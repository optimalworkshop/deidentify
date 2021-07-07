# frozen_string_literal: true

require 'deidentify/configuration'
require 'deidentify/replace'
require 'deidentify/delete'
require 'deidentify/base_hash'
require 'deidentify/hash_email'
require 'deidentify/hash_url'
require 'deidentify/delocalize_ip'
require 'deidentify/keep'
require 'deidentify/error'

module Deidentify
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end

  extend ::ActiveSupport::Concern

  POLICY_MAP = {
    replace: Deidentify::Replace,
    delete: Deidentify::Delete,
    hash: Deidentify::BaseHash,
    hash_email: Deidentify::HashEmail,
    hash_url: Deidentify::HashUrl,
    keep: Deidentify::Keep,
    delocalize_ip: Deidentify::DelocalizeIp
  }.freeze

  included do
    class_attribute :deidentify_configuration
    self.deidentify_configuration = {}

    class_attribute :associations_to_deidentify

    define_model_callbacks :deidentify
    after_deidentify :deidentify_associations!, if: -> { associations_to_deidentify.present? }
  end

  module ClassMethods
    def deidentify(column, method:, **options)
      unless POLICY_MAP.keys.include?(method) || method.respond_to?(:call)
        raise Deidentify::Error, 'you must specify a valid deidentification method'
      end

      deidentify_configuration[column] = [method, options]
    end

    def deidentify_associations(*associations)
      # TODO: how to stop loops?
      associations.each do |association_name|
        if reflect_on_association(association_name).nil?
          raise Deidentify::Error, "cannot deidentify undefined association #{association_name}"
        end
      end

      self.associations_to_deidentify = associations
    end
  end

  def deidentify!
    ActiveRecord::Base.transaction do
      run_callbacks(:deidentify) do
        deidentify_configuration.each_pair do |col, config|
          policy, options = Array(config)
          old_value = send(col)

          new_value = if policy.respond_to? :call
                        policy.call(old_value)
                      else
                        POLICY_MAP[policy].call(old_value, **options)
                      end

          write_attribute(col, new_value)
        end

        save!
      end
    end
  end

  private

  def deidentify_associations!
    associations_to_deidentify.each do |association_name|
      if collection_association?(association_name)
        send(association_name).each(&:deidentify!)
      else
        send(association_name)&.deidentify!
      end
    end
  end

  def collection_association?(association_name)
    self.class.reflect_on_association(association_name).collection?
  end
end
