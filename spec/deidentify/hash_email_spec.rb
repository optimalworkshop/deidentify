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
end
