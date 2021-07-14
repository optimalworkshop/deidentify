# frozen_string_literal: true

require 'spec_helper'

describe Deidentify do
  let(:bubble) { Bubble.create!(colour: old_colour, quantity: old_quantity) }
  let(:old_colour) { 'blue@eiffel65.com' }
  let(:old_quantity) { 150 }

  context 'no policy is defined' do
    it 'ignores all columns' do
      bubble.deidentify!
      expect(bubble.colour).to eq(old_colour)
      expect(bubble.quantity).to eq(old_quantity)
    end
  end

  context 'the policy is invalid' do
    it 'raises an error' do
      expect do
        Bubble.deidentify :colour, method: :pop
      end.to raise_error(Deidentify::Error)
    end
  end

  context 'will deidentify two columns' do
    before do
      Bubble.deidentify :colour, method: :delete
      Bubble.deidentify :quantity, method: :delete
    end

    it 'will delete both columns' do
      bubble.deidentify!

      expect(bubble.colour).to be_nil
      expect(bubble.quantity).to be_nil
    end
  end

  describe 'callbacks' do
    context 'before deidentify' do
      before do
        Bubble.before_deidentify :before_callback

        Bubble.define_method :before_callback do
          # do nothing
        end
      end

      it 'call the callback before saving' do
        expect(bubble).to receive(:before_callback).ordered
        expect(bubble).to receive(:save!).ordered

        bubble.deidentify!
      end
    end

    context 'after deidentify' do
      before do
        Bubble.after_deidentify :after_callback

        Bubble.define_method :after_callback do
          # do nothing
        end
      end

      it 'call the callback after saving' do
        expect(bubble).to receive(:save!).ordered
        expect(bubble).to receive(:after_callback).ordered

        bubble.deidentify!
      end
    end
  end

  describe 'deidentify_associations!' do
    let(:new_value) { 'hi all' }

    context 'there is an undefined association' do
      before do
        Bubble.deidentify_associations :circus
      end

      it 'will raise a error' do
        expect do
          bubble.deidentify!
        end.to raise_error Deidentify::Error
      end
    end

    context 'collection associations' do
      let(:party) { Party.create! }

      before do
        Party.deidentify_associations :bubbles
        Bubble.deidentify :colour, method: :replace, new_value: new_value
      end

      context 'when it is set' do
        let(:second_bubble) { Bubble.create!(colour: 'red') }

        before do
          party.update!(bubbles: [bubble, second_bubble])
        end

        it 'call deidentify on both bubbles' do
          party.deidentify!

          expect(bubble.reload.colour).to eq new_value
          expect(second_bubble.reload.colour).to eq new_value
        end
      end

      context 'when it is empty' do
        it 'does not call deidentify' do
          expect { party.deidentify! }.not_to raise_error
        end
      end
    end

    context 'singular associations' do
      before do
        Bubble.deidentify_associations :party
        Party.deidentify :name, method: :replace, new_value: new_value
      end

      context 'when it is set' do
        let(:party) { Party.create!(name: 'bob') }

        before do
          bubble.update!(party: party)
        end

        it 'deidentifies the party' do
          bubble.deidentify!

          expect(party.reload.name).to eq new_value
        end
      end

      context 'when it is nil' do
        it 'does not call deidentify' do
          expect { bubble.deidentify! }.not_to raise_error
        end
      end
    end

    context 'when a loop is created by deidentifing associations' do
      let(:party) { Party.create! }
      let(:second_bubble) { Bubble.create!(party: party, colour: 'red') }

      before do
        Bubble.deidentify :colour, method: :replace, new_value: 'deidentified'
        Bubble.deidentify_associations :party
        Party.deidentify_associations :bubbles

        second_bubble
        bubble.update!(party: party)
      end

      it 'should not loop forever' do
        expect do
          party.deidentify!
        end.to_not raise_error

        expect(bubble.reload.colour).to eq 'deidentified'
        expect(second_bubble.reload.colour).to eq 'deidentified'
      end
    end
  end

  describe 'lambda' do
    context 'for a string value' do
      before do
        Bubble.deidentify :colour, method: ->(bubble) { "#{bubble.colour} deidentified" }
      end

      it 'returns the lambda result' do
        bubble.deidentify!

        expect(bubble.colour).to eq("#{old_colour} deidentified")
      end
    end

    context 'for a number value' do
      before do
        Bubble.deidentify :quantity, method: ->(bubble) { bubble.quantity * 2 }
      end

      it 'returns the lambda result' do
        bubble.deidentify!

        expect(bubble.quantity).to eq(old_quantity * 2)
      end
    end
  end
end
