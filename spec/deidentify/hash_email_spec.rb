# frozen_string_literal: true

require 'spec_helper'

describe Deidentify::HashEmail do
  let(:new_email) { Deidentify::HashEmail.call(old_email) }
  let(:old_email) { 'harry.potter@hogwarts.com' }

  it "returns an email that isn't the old one" do
    expect(new_email).not_to eq(old_email)
  end

  it 'matches the email regex' do
    expect(new_email).to match(URI::MailTo::EMAIL_REGEXP)
  end

  context 'it calls the hashing service' do
    it 'calls the hashing service and prunes the domain length' do
      expect(Deidentify::BaseHash).to receive(:call).with(
        'harry.potter',
        length: 127
      ).and_return('voldemort')
      expect(Deidentify::BaseHash).to receive(:call).with(
        'hogwarts.com',
        length: Deidentify::HashEmail::MAX_DOMAIN_LENGTH
      ).and_return('deatheaters.com')

      expect(new_email).to eq('voldemort@deatheaters.com')
    end

    describe 'with a length provided' do
      let(:new_email) { Deidentify::HashEmail.call(old_email, length: length) }

      context 'an even number' do
        let(:length) { 10 }

        it 'calls the hashing service with the correct length' do
          expect(Deidentify::BaseHash).to receive(:call).with('harry.potter', length: 4).and_return('voldemort')
          expect(Deidentify::BaseHash).to receive(:call).with('hogwarts.com', length: 4).and_return('deatheaters.com')

          expect(new_email).to eq('voldemort@deatheaters.com')
        end
      end

      context 'an odd number' do
        let(:length) { 21 }

        it 'provides a email of the right length' do
          expect(new_email.length).to eq(length)
        end
      end
    end
  end

  context 'the email is nil' do
    let(:old_email) { nil }

    it 'returns nil' do
      expect(new_email).to be_nil
    end
  end

  context 'the email is blank' do
    let(:old_email) { '' }

    it 'returns blank' do
      expect(new_email).to eq old_email
    end
  end

  describe 'deidentify interface' do
    let(:bubble) { Bubble.create!(colour: old_colour, quantity: old_quantity) }
    let(:old_colour) { 'blue@eiffel65.com' }
    let(:old_quantity) { 150 }
    let(:new_email) { 'unknown' }

    context 'with length' do
      before do
        Bubble.deidentify :colour, method: :hash_email, length: length
      end

      let(:length) { 21 }

      it 'returns a hashed email' do
        expect(Deidentify::HashEmail).to receive(:call).with(old_colour, length: length).and_return(new_email)
        bubble.deidentify!

        expect(bubble.colour).to eq(new_email)
      end
    end

    context 'with no length' do
      before do
        Bubble.deidentify :colour, method: :hash_email
      end

      it 'returns a hashed email' do
        expect(Deidentify::HashEmail).to receive(:call).with(old_colour, any_args).and_return(new_email)
        bubble.deidentify!

        expect(bubble.colour).to eq(new_email)
      end
    end
  end
end
