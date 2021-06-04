# frozen_string_literal: true

require 'spec_helper'

describe Deidentify::Keep do
  let(:new_value) { Deidentify::Keep.call(old_value) }
  let(:old_value) { 'old' }

  it 'returns the old value' do
    expect(new_value).to eq(old_value)
  end
end
