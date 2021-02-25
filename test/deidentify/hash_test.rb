require 'minitest/autorun'
require 'deidentify/hash'
require 'mocha/minitest'

describe Deidentify::Hash do
  let(:new_value) { Deidentify::Hash.call(old_value) }
  let(:old_value) { "old" }

  it "returns a value that isn't the old one" do
    assert new_value != old_value
  end

  describe "calls the hashing service" do
    it "with the salt" do
      # salt value set in the configuration file
      Digest::SHA256.expects(:hexdigest).with(old_value + "ewnvi3").returns("new")

      assert_equal new_value, "new"
    end
  end

  describe "when the length is provided" do
    let(:new_value) { Deidentify::Hash.call(old_value, length: length) }
    let(:length) { 10 }

    it "truncates the hashed value" do
      assert new_value != old_value
      assert_equal new_value.length, length
    end

    describe "the length is longer than the hashed value" do
      let(:length) { 251 }

      it "doesn't extend the hash value longer than the max possible hash value length" do
        assert new_value.length < length
      end
    end
  end
end
