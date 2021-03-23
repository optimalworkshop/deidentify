require 'test_helper'

describe Deidentify do
  class Bubble < ActiveRecord::Base
    include Deidentify
  end

  before do
    ActiveRecord::Base.establish_connection :adapter => 'sqlite3', database: ':memory:'
    ActiveRecord::Base.connection.execute "CREATE TABLE bubbles (id INTEGER NOT NULL PRIMARY KEY, colour VARCHAR(32), quantity INTEGER)"

    assert_equal bubble.colour, old_colour
    assert_equal bubble.quantity, old_quantity
  end

  let(:bubble) { Bubble.create!(colour: old_colour, quantity: old_quantity) }
  let(:old_colour) { "blue@eiffel65.com" }
  let(:old_quantity) { 150 }

  describe "no policy is defined" do
    it "ignores all columns" do
      bubble.deidentify!
      assert_equal bubble.colour, old_colour
      assert_equal bubble.quantity, old_quantity
    end
  end

  describe "the policy is invalid" do
    it "raises an error" do
      assert_raises(Deidentify::Error) { Bubble.deidentify :colour, method: :pop }
    end
  end

  describe "will deidentify two columns" do
    before do
      Bubble.deidentify :colour, method: :delete
      Bubble.deidentify :quantity, method: :delete
    end

    it "will delete both columns" do
      bubble.deidentify!

      assert_nil bubble.colour
      assert_nil bubble.quantity
    end
  end

  describe "replace" do
    describe "for a string value" do
      before do
        Bubble.deidentify :colour, method: :replace, new_value: new_colour
      end

      let(:new_colour) { "iridescent" }

      it 'replaces the value' do
        bubble.deidentify!

        assert_equal bubble.colour, new_colour
      end
    end

    describe "for a number value" do
      before do
        Bubble.deidentify :quantity, method: :replace, new_value: new_quantity
      end

      let(:new_quantity) { 42 }

      it 'replaces the value' do
        bubble.deidentify!

        assert_equal bubble.quantity, new_quantity
      end
    end
  end

  describe "delete" do
    describe "for a string value" do
      before do
        Bubble.deidentify :colour, method: :delete
      end

      it 'deletes the value' do
        bubble.deidentify!

        assert_nil bubble.colour
      end
    end

    describe "for a number value" do
      before do
        Bubble.deidentify :quantity, method: :delete
      end

      it 'deletes the value' do
        bubble.deidentify!

        assert_nil bubble.quantity
      end
    end
  end

  describe "keep" do
    describe "for a string value" do
      before do
        Bubble.deidentify :colour, method: :keep
      end

      it 'does not change the value' do
        bubble.deidentify!

        assert_equal bubble.colour, old_colour
      end
    end

    describe "for a number value" do
      before do
        Bubble.deidentify :quantity, method: :keep
      end

      it 'does not change the value' do
        bubble.deidentify!

        assert_equal bubble.quantity, old_quantity
      end
    end
  end

  describe "lambda" do
    describe "for a string value" do
      before do
        Bubble.deidentify :colour, method: -> (colour) { "#{colour} deidentified" }
      end

      it "returns the lambda result" do
        bubble.deidentify!

        assert_equal bubble.colour, "#{old_colour} deidentified"
      end
    end

    describe "for a number value" do
      before do
        Bubble.deidentify :quantity, method: -> (quantity) { quantity*2 }
      end

      it "returns the lambda result" do
        bubble.deidentify!

        assert_equal bubble.quantity, old_quantity*2
      end
    end
  end

  describe "hash" do
    let(:new_hash) { "colourless" }

    describe "with length" do
      before do
        Bubble.deidentify :colour, method: :hash, length: length
      end

      let(:length) { 20 }

      it "returns a hashed value" do
        Deidentify::Hash.expects(:call).with(old_colour, length: length).returns(new_hash)
        bubble.deidentify!

        assert_equal bubble.colour, new_hash
      end
    end

    describe "with no length" do
      before do
        Bubble.deidentify :colour, method: :hash
      end

      it "returns a hashed value" do
        Deidentify::Hash.expects(:call).with(old_colour, {}).returns(new_hash)
        bubble.deidentify!

        assert_equal bubble.colour, new_hash
      end
    end
  end

  describe "hash_email" do
    let(:new_email) { "unknown" }

    describe "with length" do
      before do
        Bubble.deidentify :colour, method: :hash_email, length: length
      end

      let(:length) { 21 }

      it "returns a hashed email" do
        Deidentify::HashEmail.expects(:call).with(old_colour, length: length).returns(new_email)
        bubble.deidentify!

        assert_equal bubble.colour, new_email
      end
    end

    describe "with no length" do
      before do
        Bubble.deidentify :colour, method: :hash_email
      end

      it "returns a hashed email" do
        Deidentify::HashEmail.expects(:call).with(old_colour, {}).returns(new_email)
        bubble.deidentify!

        assert bubble.colour != old_colour
      end
    end
  end

  describe "hash_url" do
    let(:new_url) { "url" }

    describe "with length" do
      before do
        Bubble.deidentify :colour, method: :hash_url, length: length
      end

      let(:length) { 21 }

      it "returns a hashed url" do
        Deidentify::HashUrl.expects(:call).with(old_colour, length: length).returns(new_url)
        bubble.deidentify!

        assert_equal bubble.colour, new_url
      end
    end

    describe "with no length" do
      before do
        Bubble.deidentify :colour, method: :hash_url
      end

      it "returns a hashed url" do
        Deidentify::HashUrl.expects(:call).with(old_colour, {}).returns(new_url)
        bubble.deidentify!

        assert_equal bubble.colour, new_url
      end
    end
  end

  describe "delocalize_ip" do
    let(:new_ip) { "ip address" }

    describe "with mask length" do
      before do
        Bubble.deidentify :colour, method: :delocalize_ip, mask_length: mask_length
      end

      let(:mask_length) { 16 }

      it "returns a delocalized ip" do
        Deidentify::DelocalizeIp.expects(:call).with(old_colour, mask_length: mask_length).returns(new_ip)
        bubble.deidentify!

        assert_equal bubble.colour, new_ip
      end
    end

    describe "with no mask length" do
      before do
        Bubble.deidentify :colour, method: :delocalize_ip
      end

      it "returns a delocalized ip" do
        Deidentify::DelocalizeIp.expects(:call).with(old_colour, {}).returns(new_ip)
        bubble.deidentify!

        assert_equal bubble.colour, new_ip
      end
    end
  end
end
