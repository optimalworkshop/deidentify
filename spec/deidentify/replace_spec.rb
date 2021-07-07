# frozen_string_literal: true

require 'spec_helper'

describe Deidentify::Replace do
  let(:bubble) { Bubble.create!(colour: old_colour, quantity: old_quantity) }
  let(:old_colour) { 'blue@eiffel65.com' }
  let(:old_quantity) { 150 }

  context 'for a string value' do
    before do
      Bubble.deidentify :colour, method: :replace, new_value: new_colour
    end

    let(:new_colour) { 'iridescent' }

    it 'replaces the value' do
      bubble.deidentify!

      expect(bubble.colour).to eq(new_colour)
    end
  end

  context 'for a number value' do
    before do
      Bubble.deidentify :quantity, method: :replace, new_value: new_quantity
    end

    let(:new_quantity) { 42 }

    it 'replaces the value' do
      bubble.deidentify!

      expect(bubble.quantity).to eq(new_quantity)
    end
  end

  context 'for a nil value' do
    let(:old_colour) { nil }
    let(:new_colour) { 'iridescent' }

    context 'by default' do
      before do
        Bubble.deidentify :colour, method: :replace, new_value: new_colour
      end

      it 'keeps the nil' do
        bubble.deidentify!

        expect(bubble.colour).to be_nil
      end
    end

    context 'when nil should be kept' do
      before do
        Bubble.deidentify :colour, method: :replace, new_value: new_colour, keep_nil: true
      end

      it 'keeps the nil' do
        bubble.deidentify!

        expect(bubble.colour).to be_nil
      end
    end

    context 'when nil should be replaced' do
      before do
        Bubble.deidentify :colour, method: :replace, new_value: new_colour, keep_nil: false
      end

      it 'replaces the value' do
        bubble.deidentify!

        expect(bubble.colour).to eq(new_colour)
      end
    end
  end
end
