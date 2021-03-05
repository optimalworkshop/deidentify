require 'test_helper'

describe Deidentify::Delete do
  let(:new_value) { Deidentify::Delete.call("old") }

  it "returns nil" do
    assert_nil new_value
  end
end
