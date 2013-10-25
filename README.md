# ShadowModel

A rails plugin use redis to cache models data.

[![Build Status](https://travis-ci.org/cctiger36/shadow_model.png?branch=master)](https://travis-ci.org/cctiger36/shadow_model) [![Gem Version](https://badge.fury.io/rb/shadow_model.png)](http://badge.fury.io/rb/shadow_model) [![Coverage Status](https://coveralls.io/repos/cctiger36/shadow_model/badge.png)](https://coveralls.io/r/cctiger36/shadow_model) [![Code Climate](https://codeclimate.com/github/cctiger36/shadow_model.png)](https://codeclimate.com/github/cctiger36/shadow_model) [![Dependency Status](https://gemnasium.com/cctiger36/shadow_model.png)](https://gemnasium.com/cctiger36/shadow_model)

## Installation

Add this line to your application's Gemfile:

    gem 'shadow_model'

And then execute:

    $ bundle

## Usage

Add this to your model class, then the models will be cached with the assigned attributes and methods after saved or updated.

    shadow_model attribute_or_method1, attribute_or_method2, ..., options

And use this to retrieve the model from redis.

    model = YourModelClass.find_by_shadow(primary_key)

### options

<table>
  <tr>
    <td>expiration</td><td>Set the timeout of each cache.</td>
  </tr>
  <tr>
    <td>update_expiration</td><td>Reset cache expiration after model updated (if expiration has been set).</td>
  </tr>
  <tr>
    <td>expireat</td><td>Set the absolute timeout timestamp of each cache.</td>
  </tr>
</table>

### Example

    # == Schema Information
    #
    # Table name: players
    #
    #  id                   :integer          not null, primary key
    #  name                 :string(255)
    #  stamina              :integer
    #  created_at           :datetime         not null
    #  updated_at           :datetime         not null

    class Player < ActiveRecord::Base
      shadow_model :name, :stamina, :cacheable_method, expiration: 30.minutes

      def cacheable_method
        "result to cache"
      end
    end

    player = Player.create(name: "player one")
    shadow = Player.find_by_shadow(player.id)
    shadow.is_a?(Player)     # true
    shadow.shadow_model?     # true
    shadow.readonly?         # true
    shadow.reload            # reload from database
    shadow.shadow_model?     # false
    shadow.readonly?         # false

## Associations

### has_many

You can set the **shadow** option of has_many association to allow shadow_model to cache all the related models.

    class Game < ActiveRecord::Base
      has_many :players, shadow: true
    end

This will use hash data structure of redis to save the cache data, and you can retrieve all of them with one redis connection.

    game = Game.create(name: "pikmin")
    game.players.create(name: "player one")
    game.players.create(name: "player two")

    game.players_by_shadow # [#<Player id: 1, game_id: 1, name: "player one", ...>, #<Player id: 2, game_id: 1, name: "player two", ...>]

If you don't want to cache models seperately and use the association type only, you can set the **association_only** option to disable it.

    class Player < ActiveRecord::Base
      shadow_model ..., association_only: true
    end
