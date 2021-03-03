require 'test_helper'

describe Deidentify::Keep do
  let(:new_value) { Deidentify::Keep.call(old_value) }
  let(:old_value) { "old" }

  it "returns the old value" do
    assert_equal new_value, old_value
  end
end
