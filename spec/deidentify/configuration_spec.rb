# frozen_string_literal: true

require 'active_support'
require 'active_record'
require 'deidentify'
require 'rspec'

describe Deidentify::Configuration do
  context "when the gem isn't configured" do
    before do
      expect(Deidentify.configuration).to receive(:salt).and_return(nil)
    end

    it 'the hash method raises an error' do
      expect do
        Deidentify::BaseHash.call('dawn')
      end.to raise_error(Deidentify::Error)
    end

    it 'the hash email method raises an error' do
      expect do
        Deidentify::HashEmail.call('leaf.green@kanto.com')
      end.to raise_error(Deidentify::Error)
    end

    it 'the hash url method raises an error' do
      expect do
        Deidentify::HashUrl.call('https://oaklabs.com')
      end.to raise_error(Deidentify::Error)
    end
  end
end
