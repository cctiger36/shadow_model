# ShadowModel

A rails plugin use redis to cache models data.

[![Build Status](https://travis-ci.org/cctiger36/shadow_model.png?branch=master)](https://travis-ci.org/cctiger36/shadow_model) [![Gem Version](https://badge.fury.io/rb/shadow_model.png)](http://badge.fury.io/rb/shadow_model) [![Coverage Status](https://coveralls.io/repos/cctiger36/shadow_model/badge.png)](https://coveralls.io/r/cctiger36/shadow_model) [![Code Climate](https://codeclimate.com/github/cctiger36/shadow_model.png)](https://codeclimate.com/github/cctiger36/shadow_model)

## Installation

Add this line to your application's Gemfile:

    gem 'shadow_model'

And then execute:

    $ bundle

## Usage

Add this to your model class, then the models will be cached with the assigned attributes and methods after the model saved or updated.

    shadow_model attribute_or_method1, attribute_or_method2, ..., options

And use this to retrieve the model from redis.

    YourModelClass.find_by_shadow(primary_key)

### options

<table>
  <tr>
    <td>expiration</td><td>Set the timeout of each cache.</td>
  </tr>
  <tr>
    <td>&nbsp;&nbsp;update_expiration</td><td>Reset cache expiration after model updated.</td>
  </tr>
  <tr>
    <td>expireat</td><td>Set the absolute timeout timestamp of each cache.</td>
  </tr>
</table>

## Example

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
