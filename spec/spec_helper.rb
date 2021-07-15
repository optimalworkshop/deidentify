# frozen_string_literal: true

require 'rspec'
require 'active_support'
require 'active_record'
require 'deidentify'

Deidentify.configure do |config|
  config.salt = 'default'
end

class Bubble < ActiveRecord::Base
  include Deidentify

  belongs_to :party
end

class Party < ActiveRecord::Base
  include Deidentify

  has_many :bubbles
  belongs_to :main_bubble, class_name: 'Bubble'
end

RSpec.configure do |config|
  config.before do
    ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'
    ActiveRecord::Base.connection.execute 'DROP TABLE IF EXISTS bubbles'
    ActiveRecord::Base.connection.execute 'DROP TABLE IF EXISTS parties'
    ActiveRecord::Base.connection.execute(
      'CREATE TABLE bubbles (id INTEGER NOT NULL PRIMARY KEY, party_id INTEGER, colour VARCHAR(32), quantity INTEGER)'
    )
    ActiveRecord::Base.connection.execute(
      'CREATE TABLE parties (id INTEGER NOT NULL PRIMARY KEY, name VARCHAR(32), main_bubble_id INTEGER)'
    )
  end

  config.before(:each) do
    Bubble.deidentify_configuration = {}
    Bubble.associations_to_deidentify = []

    Party.deidentify_configuration = {}
    Party.associations_to_deidentify = []
  end
end
