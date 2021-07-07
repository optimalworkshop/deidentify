# frozen_string_literal: true

require 'spec_helper'

describe Deidentify::HashUrl do
  let(:new_url) { Deidentify::HashUrl.call(old_url) }
  let(:old_url) { 'https://wardrobe.com/path/to/narnia?id=2&name=edmund#white-witchs-castle' }

  it 'returns a different url' do
    expect(new_url).not_to eq(old_url)
  end

  it 'calls the hashing services' do
    expect(Deidentify::BaseHash).to receive(:call).with('wardrobe.com', length: 61).and_return('host')
    expect(Deidentify::BaseHash).to receive(:call).with('path/to/narnia', length: 61).and_return('path')
    expect(Deidentify::BaseHash).to receive(:call).with('id=2&name=edmund', length: 61).and_return('query')
    expect(Deidentify::BaseHash).to receive(:call).with('white-witchs-castle', length: 61).and_return('fragment')

    expect(new_url).to eq('https://host/path?query#fragment')
  end

  context 'when there is only a host provided' do
    let(:old_url) { 'https://wardrobe.com' }

    it 'hashes the url' do
      expect(new_url).not_to eq(old_url)
    end

    it 'only calls the hashing service once' do
      expect(Deidentify::BaseHash).to receive(:call).with('wardrobe.com', length: 244).and_return('host')

      expect(new_url).to eq('https://host')
    end
  end

  context 'when there is no fragment' do
    let(:old_url) { 'https://wardrobe.com/path/to/narnia?id=2&name=edmund' }

    it 'adjusts the length accordingly' do
      expect(Deidentify::BaseHash).to receive(:call).with('wardrobe.com', length: 81).and_return('host')
      expect(Deidentify::BaseHash).to receive(:call).with('path/to/narnia', length: 81).and_return('path')
      expect(Deidentify::BaseHash).to receive(:call).with('id=2&name=edmund', length: 81).and_return('query')

      expect(new_url).to eq('https://host/path?query')
    end
  end

  context 'when there is no protocol' do
    let(:old_url) { 'www.wardrobe.com' }

    it 'adds the protocol http' do
      expect(Deidentify::BaseHash).to receive(:call).with('www.wardrobe.com', length: 244).and_return('host')
      expect(new_url).to eq('http://host')
    end
  end

  context 'when a length is provided' do
    let(:new_url) { Deidentify::HashUrl.call(old_url, length: length) }
    let(:old_url) { 'https://wardrobe.com/path/to/narnia?id=2&name=edmund#white-witchs-castle' }
    let(:length) { 42 }

    it 'adjusts the length accordingly' do
      expect(Deidentify::BaseHash).to receive(:call).with('wardrobe.com', length: 7).and_return('host')
      expect(Deidentify::BaseHash).to receive(:call).with('path/to/narnia', length: 7).and_return('path')
      expect(Deidentify::BaseHash).to receive(:call).with('id=2&name=edmund', length: 7).and_return('query')
      expect(Deidentify::BaseHash).to receive(:call).with('white-witchs-castle', length: 7).and_return('fragment')

      expect(new_url).to eq('https://host/path?query#fragment')
    end

    it 'is the correct length' do
      expect(new_url.length).to eq(7 * 4 + 11)
    end
  end

  context 'the url is nil' do
    let(:old_url) { nil }

    it 'returns nil' do
      expect(new_url).to be_nil
    end
  end

  describe 'deidentify interface' do
    let(:bubble) { Bubble.create!(colour: old_colour, quantity: old_quantity) }
    let(:old_colour) { 'blue@eiffel65.com' }
    let(:old_quantity) { 150 }
    let(:new_url) { 'url' }

    context 'with length' do
      before do
        Bubble.deidentify :colour, method: :hash_url, length: length
      end

      let(:length) { 21 }

      it 'returns a hashed url' do
        expect(Deidentify::HashUrl).to receive(:call).with(old_colour, length: length).and_return(new_url)
        bubble.deidentify!

        expect(bubble.colour).to eq(new_url)
      end
    end

    context 'with no length' do
      before do
        Bubble.deidentify :colour, method: :hash_url
      end

      it 'returns a hashed url' do
        expect(Deidentify::HashUrl).to receive(:call).with(old_colour, any_args).and_return(new_url)
        bubble.deidentify!

        expect(bubble.colour).to eq(new_url)
      end
    end
  end
end
