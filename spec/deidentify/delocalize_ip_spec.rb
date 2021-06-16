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
end
