require 'spec_helper'

describe Game do
  let(:game) { Game.create!(name: 'game one') }
  before(:each) do
    3.times { |i| game.players.create!(name: "player#{i}") }
  end
  after(:each) { game.clear_players_shadow_cache }

  describe "players_by_shadow" do
    let(:shadow_players) { game.players_by_shadow }

    it { expect(shadow_players.size).to eq(3) }

    it { expect(shadow_players.map(&:id).sort).to eq(game.players.order(:id).map(&:id)) }

    it "shadow_players should be instances of Player" do
      shadow_players.each { |shadow_player| expect(shadow_player).to be_an_instance_of(Player) }
    end
  end

  it "should remove cache data after Player destroyed" do
    expect{ game.players.last.destroy }.to change{ game.players_by_shadow.count }.by(-1)
  end
end
