require 'minitest/autorun'
require 'mocha/minitest'
require 'active_support'
require 'active_record'
require 'deidentify'

Deidentify.configure do |config|
  config.salt = "default"
end
