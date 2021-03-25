require 'spec_helper'

describe Deidentify::Replace do
  let(:new_value) { Deidentify::Replace.call("old", new_value: replacement) }
  let(:replacement) { "new" }

  it "returns the new value" do
    expect(new_value).to eq(replacement)
  end
end
