# frozen_string_literal: true

require 'spec_helper'

describe Deidentify::Keep do
  let(:bubble) { Bubble.create!(colour: old_colour, quantity: old_quantity) }
  let(:old_colour) { 'blue@eiffel65.com' }
  let(:old_quantity) { 150 }

  context 'for a string value' do
    before do
      Bubble.deidentify :colour, method: :keep
    end

    it 'does not change the value' do
      bubble.deidentify!

      expect(bubble.colour).to eq(old_colour)
    end
  end

  context 'for a number value' do
    before do
      Bubble.deidentify :quantity, method: :keep
    end

    it 'does not change the value' do
      bubble.deidentify!

      expect(bubble.quantity).to eq(old_quantity)
    end

    it 'test failure' do
      expect(2+2).to eq(5)
    end
  end
end
