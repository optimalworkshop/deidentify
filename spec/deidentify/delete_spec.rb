# frozen_string_literal: true

require 'spec_helper'

describe Deidentify::Delete do
  let(:bubble) { Bubble.create!(colour: old_colour, quantity: old_quantity) }
  let(:old_colour) { 'blue@eiffel65.com' }
  let(:old_quantity) { 150 }

  context 'for a string value' do
    before do
      Bubble.deidentify :colour, method: :delete
    end

    it 'deletes the value' do
      bubble.deidentify!

      expect(bubble.colour).to be_nil
    end
  end

  context 'for a number value' do
    before do
      Bubble.deidentify :quantity, method: :delete
    end

    it 'deletes the value' do
      bubble.deidentify!

      expect(bubble.quantity).to be_nil
    end
  end
end
