require 'spec_helper'

describe Deidentify::Hash do
  let(:new_value) { Deidentify::Hash.call(old_value) }
  let(:old_value) { "old" }

  it "returns a value that isn't the old one" do
    expect(new_value).not_to eq(old_value)
  end

  context "calls the hashing service" do
    it "with the salt" do
      # salt value set in the configuration file
      expect(Digest::SHA256).to receive(:hexdigest).with(old_value + "default").and_return("new")

      expect(new_value).to eq("new")
    end
  end

  context "when the length is provided" do
    let(:new_value) { Deidentify::Hash.call(old_value, length: length) }
    let(:length) { 10 }

    it "truncates the hashed value" do
      expect(new_value).not_to eq(old_value)
      expect(new_value.length).to eq(length)
    end

    context "the length is longer than the hashed value" do
      let(:length) { 251 }

      it "doesn't extend the hash value longer than the max possible hash value length" do
        expect(new_value.length).to be < length
      end
    end
  end

  context "when the value is nil" do
    let(:old_value) { nil }

    it "returns nil" do
      expect(new_value).to be_nil
    end
  end
end
