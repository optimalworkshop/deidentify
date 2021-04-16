module Deidentify
  class HashUrl
    def self.call(old_url, length: 255)
      return nil if old_url.nil?

      uri = URI.parse(old_url)
      uri = URI.parse("http://#{old_url}") if uri.scheme.nil?

      hash_length = calculate_hash_length(uri, length)

      uri.host = Deidentify::BaseHash.call(uri.host, length: hash_length)
      if uri.path.present?
        uri.path = "/#{ Deidentify::BaseHash.call(remove_slash(uri.path), length: hash_length) }"
      end
      uri.query = Deidentify::BaseHash.call(uri.query, length: hash_length) if uri.query.present?
      uri.fragment = Deidentify::BaseHash.call(uri.fragment, length: hash_length) if uri.fragment.present?

      uri.to_s
    end

    private

    def self.calculate_hash_length(uri, length)
      number_of_hashes = [uri.host, uri.path, uri.query, uri.fragment].reject(&:blank?).size

      (length - "https:///?#".length)/number_of_hashes
    end

    def self.remove_slash(path)
      path[1..-1]
    end
  end
end
