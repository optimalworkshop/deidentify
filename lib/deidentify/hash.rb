module Deidentify
  class Hash
    def self.call(old_value, length: nil)
      salt = Deidentify.configuration.salt

      if salt.blank?
        raise Deidentify::Error.new("You must specify the salting value in the configuration")
      end

      hash = Digest::SHA256.hexdigest(old_value + salt)

      if length.present? && length < hash.length
        hash = hash[0, length]
      end

      hash
    end
  end
end
