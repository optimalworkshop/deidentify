# frozen_string_literal: true

module Deidentify
  class Replace
    def self.call(old_value, new_value:, keep_nil: true)
      return old_value if old_value.blank? && keep_nil

      new_value
    end
  end
end
