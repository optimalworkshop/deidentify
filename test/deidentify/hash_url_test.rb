require 'test_helper'

describe Deidentify::HashUrl do
  let(:new_url) { Deidentify::HashUrl.call(old_url) }
  let(:old_url) { "https://wardrobe.com/path/to/narnia?id=2&name=edmund#white-witchs-castle" }

  it "returns a different url" do
    assert new_url != old_url
  end

  it "calls the hashing services" do
    Deidentify::Hash.expects(:call).with("wardrobe.com", length: 61).returns("host")
    Deidentify::Hash.expects(:call).with("path/to/narnia", length: 61).returns("path")
    Deidentify::Hash.expects(:call).with("id=2&name=edmund", length: 61).returns("query")
    Deidentify::Hash.expects(:call).with("white-witchs-castle", length: 61).returns("fragment")

    assert_equal new_url, "https://host/path?query#fragment"
  end

  describe "when there is only a host provided" do
    let(:old_url) { "https://wardrobe.com" }

    it "hashes the url" do
      assert new_url != old_url
    end

    it "only calls the hashing service once" do
      Deidentify::Hash.expects(:call).with("wardrobe.com", length: 244).returns("host")

      assert_equal new_url, "https://host"
    end
  end

  describe "when there is no fragment" do
    let(:old_url) { "https://wardrobe.com/path/to/narnia?id=2&name=edmund" }

    it "adjusts the length accordingly" do
      Deidentify::Hash.expects(:call).with("wardrobe.com", length: 81).returns("host")
      Deidentify::Hash.expects(:call).with("path/to/narnia", length: 81).returns("path")
      Deidentify::Hash.expects(:call).with("id=2&name=edmund", length: 81).returns("query")

      assert_equal new_url, "https://host/path?query"
    end
  end

  describe "when a length is provided" do
    let(:new_url) { Deidentify::HashUrl.call(old_url, length: length) }
    let(:old_url) { "https://wardrobe.com/path/to/narnia?id=2&name=edmund#white-witchs-castle" }
    let(:length) { 42 }

    it "adjusts the length accordingly" do
      Deidentify::Hash.expects(:call).with("wardrobe.com", length: 7).returns("host")
      Deidentify::Hash.expects(:call).with("path/to/narnia", length: 7).returns("path")
      Deidentify::Hash.expects(:call).with("id=2&name=edmund", length: 7).returns("query")
      Deidentify::Hash.expects(:call).with("white-witchs-castle", length: 7).returns("fragment")

      assert_equal new_url, "https://host/path?query#fragment"
    end

    it "is the correct length" do
      assert new_url.length == (7 * 4 + 11)
    end
  end
end
