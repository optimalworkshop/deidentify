require 'spec_helper'

describe Deidentify do
  class Bubble < ActiveRecord::Base
    include Deidentify
  end

  before do
    ActiveRecord::Base.establish_connection :adapter => 'sqlite3', database: ':memory:'
    ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS bubbles"
    ActiveRecord::Base.connection.execute "CREATE TABLE bubbles (id INTEGER NOT NULL PRIMARY KEY, colour VARCHAR(32), quantity INTEGER)"

    expect(bubble.colour).to eq(old_colour)
    expect(bubble.quantity).to eq(old_quantity)
  end

  let(:bubble) { Bubble.create!(colour: old_colour, quantity: old_quantity) }
  let(:old_colour) { "blue@eiffel65.com" }
  let(:old_quantity) { 150 }

  context "no policy is defined" do
    it "ignores all columns" do
      bubble.deidentify!
      expect(bubble.colour).to eq(old_colour)
      expect(bubble.quantity).to eq(old_quantity)
    end
  end

  context "the policy is invalid" do
    it "raises an error" do
      expect {
        Bubble.deidentify :colour, method: :pop
      }.to raise_error(Deidentify::Error)
    end
  end

  context "will deidentify two columns" do
    before do
      Bubble.deidentify :colour, method: :delete
      Bubble.deidentify :quantity, method: :delete
    end

    it "will delete both columns" do
      bubble.deidentify!

      expect(bubble.colour).to be_nil
      expect(bubble.quantity).to be_nil
    end
  end

  describe "replace" do
    context "for a string value" do
      before do
        Bubble.deidentify :colour, method: :replace, new_value: new_colour
      end

      let(:new_colour) { "iridescent" }

      it 'replaces the value' do
        bubble.deidentify!

        expect(bubble.colour).to eq(new_colour)
      end
    end

    context "for a number value" do
      before do
        Bubble.deidentify :quantity, method: :replace, new_value: new_quantity
      end

      let(:new_quantity) { 42 }

      it 'replaces the value' do
        bubble.deidentify!

        expect(bubble.quantity).to eq(new_quantity)
      end
    end
  end

  describe "delete" do
    context "for a string value" do
      before do
        Bubble.deidentify :colour, method: :delete
      end

      it 'deletes the value' do
        bubble.deidentify!

        expect(bubble.colour).to be_nil
      end
    end

    context "for a number value" do
      before do
        Bubble.deidentify :quantity, method: :delete
      end

      it 'deletes the value' do
        bubble.deidentify!

        expect(bubble.quantity).to be_nil
      end
    end
  end

  describe "keep" do
    context "for a string value" do
      before do
        Bubble.deidentify :colour, method: :keep
      end

      it 'does not change the value' do
        bubble.deidentify!

        expect(bubble.colour).to eq(old_colour)
      end
    end

    context "for a number value" do
      before do
        Bubble.deidentify :quantity, method: :keep
      end

      it 'does not change the value' do
        bubble.deidentify!

        expect(bubble.quantity).to eq(old_quantity)
      end
    end
  end

  describe "lambda" do
    context "for a string value" do
      before do
        Bubble.deidentify :colour, method: -> (colour) { "#{colour} deidentified" }
      end

      it "returns the lambda result" do
        bubble.deidentify!

        expect(bubble.colour).to eq("#{old_colour} deidentified")
      end
    end

    context "for a number value" do
      before do
        Bubble.deidentify :quantity, method: -> (quantity) { quantity*2 }
      end

      it "returns the lambda result" do
        bubble.deidentify!

        expect(bubble.quantity).to eq(old_quantity*2)
      end
    end
  end

  describe "hash" do
    let(:new_hash) { "colourless" }

    context "with length" do
      before do
        Bubble.deidentify :colour, method: :hash, length: length
      end

      let(:length) { 20 }

      it "returns a hashed value" do
        expect(Deidentify::Hash).to receive(:call).with(old_colour, length: length).and_return(new_hash)
        bubble.deidentify!

        expect(bubble.colour).to eq(new_hash)
      end
    end

    context "with no length" do
      before do
        Bubble.deidentify :colour, method: :hash
      end

      it "returns a hashed value" do
        expect(Deidentify::Hash).to receive(:call).with(old_colour, any_args).and_return(new_hash)
        bubble.deidentify!

        expect(bubble.colour).to eq(new_hash)
      end
    end
  end

  describe "hash_email" do
    let(:new_email) { "unknown" }

    context "with length" do
      before do
        Bubble.deidentify :colour, method: :hash_email, length: length
      end

      let(:length) { 21 }

      it "returns a hashed email" do
        expect(Deidentify::HashEmail).to receive(:call).with(old_colour, length: length).and_return(new_email)
        bubble.deidentify!

        expect(bubble.colour).to eq(new_email)
      end
    end

    context "with no length" do
      before do
        Bubble.deidentify :colour, method: :hash_email
      end

      it "returns a hashed email" do
        expect(Deidentify::HashEmail).to receive(:call).with(old_colour, any_args).and_return(new_email)
        bubble.deidentify!

        expect(bubble.colour).to eq(new_email)
      end
    end
  end

  describe "hash_url" do
    let(:new_url) { "url" }

    context "with length" do
      before do
        Bubble.deidentify :colour, method: :hash_url, length: length
      end

      let(:length) { 21 }

      it "returns a hashed url" do
        expect(Deidentify::HashUrl).to receive(:call).with(old_colour, length: length).and_return(new_url)
        bubble.deidentify!

        expect(bubble.colour).to eq(new_url)
      end
    end

    context "with no length" do
      before do
        Bubble.deidentify :colour, method: :hash_url
      end

      it "returns a hashed url" do
        expect(Deidentify::HashUrl).to receive(:call).with(old_colour, any_args).and_return(new_url)
        bubble.deidentify!

        expect(bubble.colour).to eq(new_url)
      end
    end
  end

  describe "delocalize_ip" do
    let(:new_ip) { "ip address" }

    context "with mask length" do
      before do
        Bubble.deidentify :colour, method: :delocalize_ip, mask_length: mask_length
      end

      let(:mask_length) { 16 }

      it "returns a delocalized ip" do
        expect(Deidentify::DelocalizeIp).to receive(:call).with(old_colour, mask_length: mask_length).and_return(new_ip)
        bubble.deidentify!

        expect(bubble.colour).to eq(new_ip)
      end
    end

    context "with no mask length" do
      before do
        Bubble.deidentify :colour, method: :delocalize_ip
      end

      it "returns a delocalized ip" do
        expect(Deidentify::DelocalizeIp).to receive(:call).with(old_colour, any_args).and_return(new_ip)
        bubble.deidentify!

        expect(bubble.colour).to eq(new_ip)
      end
    end
  end
end
