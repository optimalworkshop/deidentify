require 'spec_helper'

describe Deidentify::Delete do
  let(:new_value) { Deidentify::Delete.call("old") }

  it "returns nil" do
    expect(new_value).to be_nil
  end
end
