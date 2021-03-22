require 'test_helper'

describe Deidentify::DelocalizeIp do
  let(:new_ip) { Deidentify::DelocalizeIp.call(old_ip) }
  let(:old_ip) { "1.2.3.4" }

  it "returns the ip network address" do
    assert_equal "1.2.3.0", new_ip
  end

  describe "the ip is nil" do
    let(:old_ip) { nil }

    it "returns nil" do
      assert_nil new_ip
    end
  end

  describe "when a network mask length is provided" do
    let(:new_ip) { Deidentify::DelocalizeIp.call(old_ip, mask_length: 16) }

    it "return the network address of given length" do
      assert_equal "1.2.0.0", new_ip
    end
  end

  describe "when delocalizing an IPv6 address" do
    let(:old_ip) { "2001:0db8:85a3:0000:0000:8a2e:0370:7334" }

    it "returns the ip network address" do
      assert_equal "2001:db8:85a3::", new_ip
    end
  end
end
