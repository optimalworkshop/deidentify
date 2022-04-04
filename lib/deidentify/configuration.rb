# frozen_string_literal: true

module Deidentify
  class Configuration
    attr_accessor :salt, :scope

    def initialize
      @salt = nil
      @scope = scope
    end
  end
end
