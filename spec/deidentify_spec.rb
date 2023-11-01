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

  context 'the policy is for a column that does not exist' do
    let(:logger) { instance_double(Logger, error: nil) }

    before do
      allow(Rails).to receive(:logger).and_return logger

      Bubble.deidentify :oops, method: :delete
      Bubble.deidentify :colour, method: :delete
    end

    it 'still deidentifies other columns' do
      bubble.deidentify!

      expect(bubble.colour).to be_nil
    end

    it 'logs an error' do
      expect(logger).to receive(:error).with(
        "ERROR: Deidentification policy defined for oops but column doesn't exist in bubbles"
      )

      bubble.deidentify!
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

  context 'with a configuration scope' do
    let(:bubble) { Bubble.create!(name: 'seventy-three') }

    before do
      Deidentify.configure do |config|
        config.scope = ->(klass_or_association) { klass_or_association.where('name is null OR length(name) < 10') }
      end

      Bubble.deidentify :name, method: :delete
    end

    it 'will not deidentify if the scope excludes it' do
      bubble.deidentify!

      expect(bubble.name).to_not be_nil
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

    context 'when called more than once' do
      let(:second_bubble) { Bubble.create!(colour: 'red') }
      let(:party) { Party.create! }

      before do
        Party.deidentify_associations :bubbles
        Party.deidentify_associations :main_bubble
        Bubble.deidentify :colour, method: :replace, new_value: new_value

        party.update!(bubbles: [second_bubble], main_bubble: bubble)
      end

      it 'call deidentify on all associations' do
        party.deidentify!
        expect(bubble.reload.colour).to eq new_value
        expect(second_bubble.reload.colour).to eq new_value
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

    context 'when a default scope is passed in via the configuration' do
      let(:new_value) { "it's deidentified" }

      before do
        Bubble.deidentify :name, method: :replace, new_value: new_value
        Party.deidentify :name, method: :replace, new_value: new_value
      end

      context 'the association has no scope' do
        before do
          Deidentify.configure do |config|
            config.scope = ->(klass_or_association) { klass_or_association.where('name is null OR length(name) < 10') }
          end
        end

        context 'collection associations' do
          let(:party) { Party.create! }
          let(:less_than_ten) { Bubble.create!(party: party, name: 'fourteen') }
          let(:greater_than_ten) { Bubble.create!(party: party, name: 'seventy-three') }

          before do
            Party.deidentify_associations :bubbles

            less_than_ten
            greater_than_ten
          end

          it 'should use the configuration scope' do
            party.deidentify!

            expect(less_than_ten.reload.name).to eq new_value
            expect(greater_than_ten.reload.name).to eq 'seventy-three'
          end
        end

        context 'has one associations' do
          let(:party) { Party.create! }

          before do
            Party.has_one :bubble, class_name: 'Bubble', foreign_key: 'party_id'
            Party.deidentify_associations :bubble
          end

          context 'when scope excludes record' do
            let(:greater_than_ten) { Bubble.create!(party: party, name: 'seventy-three') }

            before do
              greater_than_ten
            end

            it 'should use the default scope' do
              party.deidentify!

              expect(greater_than_ten.reload.name).to eq 'seventy-three'
            end
          end

          context 'when scope includes record' do
            let(:less_than_ten) { Bubble.create!(party: party, name: 'four') }

            before do
              less_than_ten
            end

            it 'should use the default scope' do
              party.deidentify!

              expect(less_than_ten.reload.name).to eq new_value
            end
          end
        end

        context 'belongs to association' do
          let(:bubble) { Bubble.create!(party: party) }

          before do
            Bubble.deidentify_associations :party
          end

          context 'when scope excludes record' do
            let(:party) { Party.create!(name: 'seventy-three') }

            it 'should use the default scope' do
              bubble.deidentify!

              expect(party.reload.name).to eq 'seventy-three'
            end
          end

          context 'when scope includes record' do
            let(:party) { Party.create!(name: 'four') }

            it 'should use the default scope' do
              bubble.deidentify!

              expect(party.reload.name).to eq new_value
            end
          end
        end
      end

      context 'the association has a scope' do
        before do
          Deidentify.configure do |config|
            config.scope = ->(klass_or_association) { klass_or_association.where('name is null OR length(name) >= 5') }
          end
        end

        context 'collection association' do
          let(:party) { Party.create! }
          let(:less_than_five) { Bubble.create!(party: party, name: 'four') }
          let(:less_than_ten) { Bubble.create!(party: party, name: 'seven') }
          let(:greater_than_ten) { Bubble.create!(party: party, name: 'seventy-three') }

          before do
            Party.has_many :small_bubbles,
              -> { where('length(name) < 10') },
              class_name: 'Bubble',
              foreign_key: 'party_id'
            Party.deidentify_associations :small_bubbles

            less_than_five
            less_than_ten
            greater_than_ten
          end

          it 'should apply both scopes' do
            party.deidentify!

            expect(less_than_five.reload.name).to eq 'four'
            expect(less_than_ten.reload.name).to eq new_value
            expect(greater_than_ten.reload.name).to eq 'seventy-three'
          end
        end

        context 'has one association' do
          let(:party) { Party.create! }
          let(:less_than_five) { Bubble.create!(party: party, name: 'four') }

          before do
            Party.has_one :small_bubble,
              -> { where('length(name) < 10') },
              class_name: 'Bubble',
              foreign_key: 'party_id'
            Party.deidentify_associations :small_bubble

            less_than_five
          end

          it 'should apply both scopes' do
            party.deidentify!

            expect(less_than_five.reload.name).to eq 'four'
          end
        end

        context 'belongs to association' do
          let(:less_than_five) { Party.create!(name: 'four') }
          let(:bubble) { Bubble.create!(party: less_than_five) }

          before do
            Bubble.belongs_to :small_party,
              -> { where('length(name) < 10') },
              class_name: 'Party',
              foreign_key: 'party_id'
            Bubble.deidentify_associations :small_party
          end

          it 'should apply both scopes' do
            bubble.deidentify!

            expect(less_than_five.reload.name).to eq 'four'
          end
        end
      end

      context 'with a default scope' do
        before do
          Party.default_scopes = [-> { where('length(name) < 10') }]
          Bubble.default_scopes = [-> { where('length(name) < 10') }]

          Deidentify.configure do |config|
            config.scope = ->(klass_or_association) { klass_or_association.unscoped }
          end
        end

        context 'collection associations' do
          let(:party) { Party.create! }
          let(:greater_than_ten) { Bubble.create!(party: party, name: 'seventy-three') }

          before do
            Party.deidentify_associations :bubbles

            greater_than_ten
          end

          it 'should override the default scope' do
            party.deidentify!

            expect(greater_than_ten.reload.name).to eq new_value
          end
        end

        context 'has one associations' do
          let(:party) { Party.create! }
          let(:greater_than_ten) { Bubble.create!(party: party, name: 'seventy-three') }

          before do
            Party.has_one :bubble, class_name: 'Bubble', foreign_key: 'party_id'
            Party.deidentify_associations :bubble

            greater_than_ten
          end

          it 'should override the default scope' do
            party.deidentify!

            expect(greater_than_ten.reload.name).to eq new_value
          end
        end

        context 'belongs to association' do
          let(:bubble) { Bubble.create!(party: party) }
          let(:party) { Party.create!(name: 'seventy-three') }

          before do
            Bubble.deidentify_associations :party
          end

          it 'should override the default scope' do
            bubble.deidentify!

            expect(party.reload.name).to eq new_value
          end
        end
      end
    end
  end

  describe 'deidentified_at' do
    context 'is defined' do
      let(:party) { Party.create! }

      it 'should set it' do
        party.deidentify!

        expect(party.deidentified_at).to_not be_nil
      end
    end

    context 'is not defined' do
      it 'should not throw a error' do
        expect { bubble.deidentify! }.to_not raise_error
      end
    end
  end

  describe '#deidentify_attributes' do
    let(:party) { Party.create!(main_bubble: bubble, name: 'Happy Birthday') }
    let(:bubble) { Bubble.create!(colour: 'purple') }

    before do
      Party.deidentify :name, method: :delete
      Party.deidentify_associations :main_bubble

      Bubble.deidentify :colour, method: :delete

      party.deidentify_attributes
    end

    it 'deidentifies the record' do
      expect(party.name).to be_nil
    end

    it 'does not save the record' do
      expect(party).to be_changed
    end

    it 'does not run callbacks' do
      expect(party.main_bubble.colour).to_not be_nil
    end

    it 'does not set deidentified_at' do
      expect(party.deidentified_at).to be_nil
    end
  end

  describe 'validate' do
    before do
      Party.validates :name, presence: true
      Bubble.validates :colour, presence: true

      Party.deidentify_associations :bubbles

      Party.deidentify :name, method: :delete
      Bubble.deidentify :colour, method: :delete
    end

    let!(:party) { Party.create!(name: 'Christmas') }
    let!(:bubble) { Bubble.create!(colour: 'red', party: party) }

    context 'false' do
      it 'saves an invalid record' do
        party.deidentify!(validate: false)

        expect(party.name).to be_nil
      end

      it 'saves an associated invalid record' do
        party.deidentify!(validate: false)

        expect(bubble.reload.colour).to be_nil
      end
    end

    context 'true' do
      it 'does not save an invalid record' do
        expect { party.deidentify! }.to raise_error ActiveRecord::RecordInvalid, /Name can't be blank/
      end

      it 'does not save an associated invalid record' do
        Party.deidentify :name, method: :keep

        expect { party.deidentify! }.to raise_error ActiveRecord::RecordInvalid, /Colour can't be blank/
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
