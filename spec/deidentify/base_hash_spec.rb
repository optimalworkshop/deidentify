# frozen_string_literal: true

require 'spec_helper'

describe Deidentify::BaseHash do
  let(:new_value) { Deidentify::BaseHash.call(old_value) }
  let(:old_value) { 'old' }

  it "returns a value that isn't the old one" do
    expect(new_value).not_to eq(old_value)
  end

  context 'calls the hashing service' do
    it 'with the salt' do
      # salt value set in the configuration file
      expect(Digest::SHA256).to receive(:hexdigest).with("#{old_value}default").and_return('new')

      expect(new_value).to eq('new')
    end
  end

  context 'when the length is provided' do
    let(:new_value) { Deidentify::BaseHash.call(old_value, length: length) }
    let(:length) { 10 }

    it 'truncates the hashed value' do
      expect(new_value).not_to eq(old_value)
      expect(new_value.length).to eq(length)
    end

    context 'the length is longer than the hashed value' do
      let(:length) { 251 }

      it "doesn't extend the hash value longer than the max possible hash value length" do
        expect(new_value.length).to be < length
      end
    end
  end

  context 'when the value is nil' do
    let(:old_value) { nil }

    it 'returns nil' do
      expect(new_value).to be_nil
    end
  end

  describe 'deidentify interface' do
    let(:bubble) { Bubble.create!(colour: old_colour, quantity: old_quantity) }
    let(:old_colour) { 'blue@eiffel65.com' }
    let(:old_quantity) { 150 }
    let(:new_hash) { 'colourless' }

    context 'with length' do
      before do
        Bubble.deidentify :colour, method: :hash, length: length
      end

      let(:length) { 20 }

      it 'returns a hashed value' do
        expect(Deidentify::BaseHash).to receive(:call).with(old_colour, length: length).and_return(new_hash)
        bubble.deidentify!

        expect(bubble.colour).to eq(new_hash)
      end
    end

    context 'with no length' do
      before do
        Bubble.deidentify :colour, method: :hash
      end

      it 'returns a hashed value' do
        expect(Deidentify::BaseHash).to receive(:call).with(old_colour, any_args).and_return(new_hash)
        bubble.deidentify!

        expect(bubble.colour).to eq(new_hash)
      end
    end
  end
end
