# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'deidentify'
  s.version     = '2.6.0'
  s.summary     = 'Deidentify a rails model'
  s.description = 'A gem to allow deidentification of certain fields'
  s.authors     = ['Lucy Dement']
  s.homepage    = 'https://github.com/optimalworkshop/deidentify'
  s.license     = 'MIT'
  s.files       = Dir['lib/**/*.rb']

  s.required_rubygems_version
  s.required_ruby_version = '>= 2.6'
  s.add_runtime_dependency 'rails', '>= 5.0.0'
end
