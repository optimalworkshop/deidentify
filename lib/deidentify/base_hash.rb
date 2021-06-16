# frozen_string_literal: true

module Deidentify
  class BaseHash
    def self.call(old_value, length: nil)
      return nil if old_value.nil?

      salt = Deidentify.configuration.salt

      raise Deidentify::Error, 'You must specify the salting value in the configuration' if salt.blank?

      hash = Digest::SHA256.hexdigest(old_value + salt)

      hash = hash[0, length] if length.present? && length < hash.length

      hash
    end
  end
end
