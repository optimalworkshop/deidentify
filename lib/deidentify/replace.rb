module Deidentify
  class Replace
    def self.call(old_value, new_value:, keep_nil: true)
      return nil if old_value.nil? && keep_nil

      new_value
    end
  end
end
