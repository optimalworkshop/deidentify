require 'minitest/autorun'
require 'active_support'
require 'active_record'

require 'deidentify'

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
  let(:old_colour) { "blue" }
  let(:old_quantity) { 150 }

  describe "the policy is invalid" do
    it "raises an error" do
      assert_raises(Deidentify::DeidentifyError) { Bubble.deidentify :colour, method: :pop }
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
end