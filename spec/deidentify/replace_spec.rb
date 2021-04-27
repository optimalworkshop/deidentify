require 'spec_helper'

describe Deidentify::Replace do
  let(:new_value) { Deidentify::Replace.call(old_value, new_value: replacement) }
  let(:replacement) { "new" }
  let(:old_value) { "old" }

  it "returns the new value" do
    expect(new_value).to eq(replacement)
  end

  context "when the old value is nil" do
    let(:old_value) { nil }

    context "nils should be retained" do
      it "returns nil" do
        expect(new_value).to be_nil
      end
    end

    context "nils should be replaced" do
      let(:new_value) { Deidentify::Replace.call(old_value, new_value: replacement, keep_nil: false) }

      it "returns the new value" do
        expect(new_value).to eq(replacement)
      end
    end
  end
end
