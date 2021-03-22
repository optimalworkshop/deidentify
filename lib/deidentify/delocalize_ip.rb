module Deidentify
  class DelocalizeIp
    def self.call(old_ip, mask_length: nil)
      return nil if old_ip.nil?

      addr = IPAddr.new(old_ip)
      addr.mask(mask_length || default_mask(addr)).to_s
    end

    private

    def self.default_mask(addr)
      addr.ipv4? ? 24 : 48
    end
  end
end
