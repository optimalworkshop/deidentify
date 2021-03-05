module Deidentify
  class HashUrl
    def self.call(old_url, length: 255)
      uri = URI.parse(old_url)

      hash_length = calculate_hash_length(uri, length)

      uri.host = Deidentify::Hash.call(uri.host, length: hash_length)
      if uri.path.present?
        uri.path = "/#{ Deidentify::Hash.call(remove_slash(uri.path), length: hash_length) }"
      end
      uri.query = Deidentify::Hash.call(uri.query, length: hash_length) if uri.query.present?
      uri.fragment = Deidentify::Hash.call(uri.fragment, length: hash_length) if uri.fragment.present?

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
