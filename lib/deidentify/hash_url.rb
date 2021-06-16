# frozen_string_literal: true

module Deidentify
  class HashUrl
    def self.call(old_url, length: 255)
      return nil if old_url.nil?

      uri = URI.parse(old_url)
      uri = URI.parse("http://#{old_url}") if uri.scheme.nil?

      hash_length = calculate_hash_length(uri, length)

      hash_host(uri, hash_length)
      hash_path(uri, hash_length)
      hash_query(uri, hash_length)
      hash_fragment(uri, hash_length)

      uri.to_s
    end

    def self.calculate_hash_length(uri, length)
      number_of_hashes = [uri.host, uri.path, uri.query, uri.fragment].reject(&:blank?).size

      (length - 'https:///?#'.length) / number_of_hashes
    end

    def self.hash_host(uri, hash_length)
      uri.host = Deidentify::BaseHash.call(uri.host, length: hash_length)
    end

    def self.hash_path(uri, hash_length)
      uri.path = "/#{Deidentify::BaseHash.call(remove_slash(uri.path), length: hash_length)}" if uri.path.present?
    end

    def self.remove_slash(path)
      path[1..]
    end

    def self.hash_query(uri, hash_length)
      uri.query = Deidentify::BaseHash.call(uri.query, length: hash_length) if uri.query.present?
    end

    def self.hash_fragment(uri, hash_length)
      uri.fragment = Deidentify::BaseHash.call(uri.fragment, length: hash_length) if uri.fragment.present?
    end
  end
end
