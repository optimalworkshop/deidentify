# frozen_string_literal: true

module Deidentify
  class HashEmail
    # 63 is the longest domain that is still acceptable for URI::MailTo::EMAILS_REGEXP
    MAX_DOMAIN_LENGTH = 63

    def self.call(old_email, length: 255)
      return old_email unless old_email.present?

      half_length = (length - 1) / 2 # the -1 is to account for the @ symbol

      name, domain = old_email.split('@')

      hashed_name = Deidentify::BaseHash.call(name, length: half_length)
      hashed_domain = Deidentify::BaseHash.call(domain, length: [half_length, MAX_DOMAIN_LENGTH].min)

      "#{hashed_name}@#{hashed_domain}"
    end
  end
end
