require 'minitest/autorun'
require 'deidentify/current_value'

describe Deidentify::CurrentValue do
  let(:new_value) { Deidentify::CurrentValue.call(old_value) }
  let(:old_value) { "old" }

  it "returns the old value" do
    assert_equal new_value, old_value
  end
end
