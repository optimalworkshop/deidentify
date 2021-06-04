# frozen_string_literal: true

require 'rspec'
require 'active_support'
require 'active_record'
require 'deidentify'

Deidentify.configure do |config|
  config.salt = 'default'
end
