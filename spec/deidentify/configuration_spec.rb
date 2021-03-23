require 'active_support'
require 'active_record'
require 'deidentify'
require 'rspec'

describe Deidentify::Configuration do
  context "when the gem isn't configured" do
    before do
      expect(Deidentify.configuration).to receive(:salt).and_return(nil)
    end

    it "the hash method raises an error" do
      expect {
        Deidentify::Hash.call("dawn")
      }.to raise_error(Deidentify::Error)
    end

    it "the hash email method raises an error" do
      expect {
        Deidentify::HashEmail.call("leaf.green@kanto.com")
      }.to raise_error(Deidentify::Error)
    end

    it "the hash url method raises an error" do
      expect {
        Deidentify::HashUrl.call("https://oaklabs.com")
      }.to raise_error(Deidentify::Error)
    end
  end
end
