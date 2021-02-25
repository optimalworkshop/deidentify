module Deidentify
  class Hash
    def self.call(old_value, length: nil)
      salt = Deidentify.configuration.salt
      hash = Digest::SHA256.hexdigest(old_value + salt)

      if length.present?
        hash = hash[0, length]
      end

      hash
    end
  end
end
