require 'spec_helper'

describe "Association" do
  let(:game) { Game.create!(name: 'game one') }
  let(:player) { Player.create!(name: 'player one', stamina: 3, tension: 5, game_id: game.id) }
  let(:shadow_player) { Player.find_by_shadow(player.id) }
  after { player.clear_shadow_data }

  it "should return associated model when call the association methods" do
    shadow_player.game.should == player.game
  end
end
