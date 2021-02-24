Gem::Specification.new do |s|
  s.name        = 'deidentify'
  s.version     = '0.0.0'
  s.summary     = "Deidentify a rails model"
  s.description = "A gem to allow deidentification of certain fields"
  s.authors     = ["Lucy Dement"]
  s.files       = ["lib/deidentify.rb"]

  s.required_rubygems_version
  s.add_runtime_dependency "rails", ">= 5.0.0"
end
