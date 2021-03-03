require 'minitest/autorun'
require 'mocha/minitest'
require 'active_support'
require 'active_record'
require 'deidentify'

describe Deidentify::Configuration do
  describe "when the gem isn't configured" do
    before do
      Deidentify.configuration.expects(:salt).returns(nil)
    end

    it "the hash method raises an error" do
      assert_raises(Deidentify::Error) do
        Deidentify::Hash.call("dawn")
      end
    end

    it "the hash email method raises an error" do
      assert_raises(Deidentify::Error) do
        Deidentify::HashEmail.call("leaf.green@kanto.com")
      end
    end

    it "the hash url method raises an error" do
      assert_raises(Deidentify::Error) do
        Deidentify::HashUrl.call("https://oaklabs.com")
      end
    end
  end
end
