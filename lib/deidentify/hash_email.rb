module Deidentify
  class HashEmail
    # 63 is the longest domain that is still acceptable for URI::MailTo::EMAILS_REGEXP
    MAX_DOMAIN_LENGTH = 63

    def self.call(old_email, length: 255)
      half_length = (length - 1)/2 # the -1 is to account for the @ symbol

      name, domain = old_email.split('@')

      hashed_name = Deidentify::Hash.call(name, length: half_length)
      hashed_domain = Deidentify::Hash.call(domain, length: [half_length, MAX_DOMAIN_LENGTH].min)

      "#{hashed_name}@#{hashed_domain}"
    end
  end
end
