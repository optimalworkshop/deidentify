# frozen_string_literal: true

require 'spec_helper'

describe Deidentify::DelocalizeIp do
  let(:new_ip) { Deidentify::DelocalizeIp.call(old_ip) }
  let(:old_ip) { '1.2.3.4' }

  it 'returns the ip network address' do
    expect(new_ip).to eq('1.2.3.0')
  end

  context 'the ip is nil' do
    let(:old_ip) { nil }

    it 'returns nil' do
      expect(new_ip).to be_nil
    end
  end

  context 'the ip is blank' do
    let(:old_ip) { '' }

    it 'returns blank string' do
      expect(new_ip).to eq old_ip
    end
  end

  context 'when a network mask length is provided' do
    let(:new_ip) { Deidentify::DelocalizeIp.call(old_ip, mask_length: 16) }

    it 'return the network address of given length' do
      expect(new_ip).to eq('1.2.0.0')
    end
  end

  context 'when delocalizing an IPv6 address' do
    let(:old_ip) { '2001:0db8:85a3:0000:0000:8a2e:0370:7334' }

    it 'returns the ip network address' do
      expect(new_ip).to eq('2001:db8:85a3::')
    end
  end

  describe 'deidentify interface' do
    let(:bubble) { Bubble.create!(colour: old_colour, quantity: old_quantity) }
    let(:old_colour) { 'blue@eiffel65.com' }
    let(:old_quantity) { 150 }
    let(:new_ip) { 'ip address' }

    context 'with mask length' do
      before do
        Bubble.deidentify :colour, method: :delocalize_ip, mask_length: mask_length
      end

      let(:mask_length) { 16 }

      it 'returns a delocalized ip' do
        expect(Deidentify::DelocalizeIp).to receive(:call).with(old_colour, mask_length: mask_length).and_return(new_ip)
        bubble.deidentify!

        expect(bubble.colour).to eq(new_ip)
      end
    end

    context 'with no mask length' do
      before do
        Bubble.deidentify :colour, method: :delocalize_ip
      end

      it 'returns a delocalized ip' do
        expect(Deidentify::DelocalizeIp).to receive(:call).with(old_colour, any_args).and_return(new_ip)
        bubble.deidentify!

        expect(bubble.colour).to eq(new_ip)
      end
    end
  end
end
