# frozen_string_literal: true

require 'rails'
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
  has_many :comments, as: :commentable
end

class Party < ActiveRecord::Base
  include Deidentify

  has_many :bubbles
  has_many :comments, as: :commentable
  belongs_to :main_bubble, class_name: 'Bubble'
end

class Comment < ActiveRecord::Base
  include Deidentify

  belongs_to :commentable, polymorphic: true
end

RSpec.configure do |config|
  config.before do
    ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'
    ActiveRecord::Base.connection.execute 'DROP TABLE IF EXISTS bubbles'
    ActiveRecord::Base.connection.execute 'DROP TABLE IF EXISTS parties'
    ActiveRecord::Base.connection.execute 'DROP TABLE IF EXISTS comments'
    ActiveRecord::Base.connection.execute(
      'CREATE TABLE bubbles (
        id INTEGER NOT NULL PRIMARY KEY,
        party_id INTEGER,
        colour VARCHAR(32),
        name VARCHAR(32),
        quantity INTEGER
      )'
    )
    ActiveRecord::Base.connection.execute(
      'CREATE TABLE parties (
        id INTEGER NOT NULL PRIMARY KEY,
        name VARCHAR(32),
        main_bubble_id INTEGER,
        deidentified_at DATETIME
      )'
    )
    ActiveRecord::Base.connection.execute(
      'CREATE TABLE comments (
        id INTEGER NOT NULL PRIMARY KEY,
        commentable_id INTEGER,
        commentable_type VARCHAR(32),
        body VARCHAR(64),
        name VARCHAR(32)
      )'
    )
  end

  config.before(:each) do
    Bubble.deidentify_configuration = {}
    Bubble.associations_to_deidentify = []
    Bubble.default_scopes = []

    Party.deidentify_configuration = {}
    Party.associations_to_deidentify = []
    Party.default_scopes = []

    Comment.deidentify_configuration = {}
    Comment.associations_to_deidentify = []
    Comment.default_scopes = []

    Deidentify.configuration.scope = nil
  end
end
