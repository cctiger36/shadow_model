require 'spec_helper'

describe Player do
  let(:player) { Player.create!(name: 'player one', stamina: 3, tension: 5) }
  after { player.clear_shadow_data }

  it "should put data to cache after saved" do
    Redis.current.get(player.shadow_cache_key).should_not be_nil
  end

  it "should clear cached data after destroyed" do
    player.destroy
    expect(Player.find_shadow_data(player.id)).to be_nil
  end

  describe ".find_shadow_data" do
    it "should retrieve cache data as a hash" do
      Player.find_shadow_data(player.id).should be_an_instance_of Hash
    end

    it "should save data to cache first cache data not exists" do
      player.clear_shadow_data
      shadow_player = Player.find_by_shadow(player.id)
      Redis.current.get(player.shadow_cache_key).should_not be_nil
      shadow_player.should be_shadow_model
    end
  end

  describe ".find_by_shadow" do
    it "should find the model of given id from cache" do
      Player.should_not_receive(:find_by_sql)
      Player.find_by_shadow(player.id)
    end
  end

  context "the shadow model" do
    let(:shadow_player) { Player.find_by_shadow(player.id) }

    it { expect(shadow_player).to be_an_instance_of Player }
    it { expect(shadow_player).to be_shadow_model }
    it { expect(shadow_player).to be_persisted }

    it "should cannot be save or update" do
      expect{ shadow_player.save! }.to raise_error
    end

    it "should redefine the cacheable methods" do
      shadow_player.should respond_to :cacheable_method_without_shadow
      shadow_player.method(:cacheable_method).should == shadow_player.method(:cacheable_method_with_shadow)
    end

    it "should retrieve data from cache when call the cached methods" do
      shadow_player.shadow_data.should_receive(:[]).with(:cacheable_method)
      shadow_player.cacheable_method
    end

    it "should retrieve data from cache when call the cached attributes" do
      shadow_player.shadow_data.should_receive(:[]).with(:name)
      shadow_player.name
    end

    it "should cache primary key as default" do
      shadow_player.shadow_data.keys.should include(:id)
    end

    it "should have same values with the original model" do
      shadow_player.id.should == player.id
      shadow_player.name.should == player.name
      shadow_player.stamina.should == player.stamina
      shadow_player.tension.should == player.tension
      shadow_player.cacheable_method.should == player.cacheable_method
    end

    it "should can call the uncached methods as the original model" do
      shadow_player.not_cacheable_method.should == :not_cacheable_method
    end
  end

  context "shadow expiration setted" do
    before do
      Player.shadow_options[:expiration] = 10.seconds
      player.save!
    end

    after { Player.shadow_options = {} }

    it "should expire after setted expiration" do
      player.shadow_ttl.should be_between 9, 10
    end

    it "should update expiration everytime cache updated if update_expiration setted" do
      Player.shadow_options[:update_expiration] = true
      player.shadow_ttl.should be_between 9, 10
      Player.shadow_options[:expiration] = 20.seconds
      player.save!
      player.shadow_ttl.should be_between 19, 20
    end
  end

  context "shadow expireat setted" do
    before do
      Player.shadow_options[:expireat] = Time.now + 30.seconds
      player.save!
    end

    after { Player.shadow_options = {} }

    it "should expire after setted expireat" do
      player.shadow_ttl.should be_between 29, 30
    end
  end

  context "association" do
    let(:game) { Game.create!(name: 'game one') }
    let(:associated_player) { Player.create!(name: 'player one', stamina: 3, tension: 5, game_id: game.id) }
    let(:shadow_player) { Player.find_by_shadow(associated_player.id) }
    after { associated_player.clear_shadow_data }

    it "should return associated model when call the association methods" do
      shadow_player.game.should == associated_player.game
    end
  end

  context "association_only option" do
    before { Player.shadow_options[:association_only] = true }
    after { Player.shadow_options[:association_only] = false }
    it "should not cache model data seperately" do
      expect(Player.find_shadow_data(player.id)).to be_nil
    end
  end

  describe "reload" do
    let(:reloaded_model) { Player.find_by_shadow(player.id).reload }
    it "should no longer be a shadow_model" do
      expect(reloaded_model).not_to be_shadow_model
    end

    it "should reload remove the readonly attribute" do
      expect(reloaded_model).not_to be_readonly
    end
  end
end
