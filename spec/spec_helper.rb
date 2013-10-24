$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'redis'
require 'shadow_model'
require 'coveralls'
Coveralls.wear!

REDIS_PORT = ENV['REDIS_PORT'] || 6379
REDIS_HOST = ENV['REDIS_HOST'] || 'localhost'

Redis.current = Redis.new(host: REDIS_HOST, port: REDIS_PORT)

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')

ActiveRecord::Schema.define(:version => 0) do
  create_table :players do |t|
    t.integer :game_id
    t.string :name
    t.integer :stamina
    t.integer :tension
    t.timestamps
  end

  create_table :games do |t|
    t.string :name
    t.timestamps
  end
end

RSpec.configure do |config|
  config.after(:all) do
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.execute("DELETE FROM #{table}")
    end
  end
end

class Player < ActiveRecord::Base
  shadow_model :name, :stamina, :tension, :game_id, :cacheable_method

  belongs_to :game

  def cacheable_method
    __method__
  end

  def not_cacheable_method
    __method__
  end
end

class Game < ActiveRecord::Base
  has_many :players, shadow: true
end
