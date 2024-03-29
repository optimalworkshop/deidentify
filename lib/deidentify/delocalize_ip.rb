# frozen_string_literal: true

module Deidentify
  class DelocalizeIp
    def self.call(old_ip, mask_length: nil)
      return old_ip unless old_ip.present?

      addr = IPAddr.new(old_ip)
      addr.mask(mask_length || default_mask(addr)).to_s
    end

    def self.default_mask(addr)
      addr.ipv4? ? 24 : 48
    end
  end
end
