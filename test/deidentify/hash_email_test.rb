require 'test_helper'

describe Deidentify::HashEmail do
  let(:new_email) { Deidentify::HashEmail.call(old_email) }
  let(:old_email) { "harry.potter@hogwarts.com" }

  it "returns an email that isn't the old one" do
    assert new_email != old_email
  end

  it "matches the email regex" do
    assert new_email.match?(URI::MailTo::EMAIL_REGEXP)
  end

  describe "it calls the hashing service" do
    it "calls the hashing service and prunes the domain length" do
      Deidentify::Hash.expects(:call).with(
        "harry.potter",
        length: 127
      ).returns("voldemort")
      Deidentify::Hash.expects(:call).with(
        "hogwarts.com",
        length: Deidentify::HashEmail::MAX_DOMAIN_LENGTH
      ).returns("deatheaters.com")

      assert_equal new_email, "voldemort@deatheaters.com"
    end

    describe "with a length provided" do
      let(:new_email) { Deidentify::HashEmail.call(old_email, length: length) }

      describe "an even number" do
        let(:length) { 10 }

        it "calls the hashing service with the correct length" do
          Deidentify::Hash.expects(:call).with("harry.potter", length: 4).returns("voldemort")
          Deidentify::Hash.expects(:call).with("hogwarts.com", length: 4).returns("deatheaters.com")

          assert_equal new_email, "voldemort@deatheaters.com"
        end
      end

      describe "an odd number" do
        let(:length) { 21 }

        it "provides a email of the right length" do
          assert_equal new_email.length, length
        end
      end
    end
  end
end
