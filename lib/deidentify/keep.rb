# frozen_string_literal: true

module Deidentify
  class Keep
    def self.call(old_value)
      old_value
    end
  end
end
