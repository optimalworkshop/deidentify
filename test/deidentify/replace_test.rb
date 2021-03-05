require 'test_helper'

describe Deidentify::Replace do
  let(:new_value) { Deidentify::Replace.call("old", new_value: replacement) }
  let(:replacement) { "new" }

  it "returns the new value" do
    assert_equal new_value, replacement
  end
end
