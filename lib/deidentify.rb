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
      associations.each do |association_name|
        if reflect_on_association(association_name).nil?
          raise Deidentify::Error, "cannot deidentify undefined association #{association_name}"
        end
      end

      self.associations_to_deidentify = associations
    end
  end

  def deidentify!
    recursive_deidentify!(deidentified_objects: [])
  end

  protected

  def recursive_deidentify!(deidentified_objects:)
    ActiveRecord::Base.transaction do
      @deidentified_objects = deidentified_objects

      run_callbacks(:deidentify) do
        deidentify_configuration.each_pair do |col, config|
          deidentify_column(col, config)
        end

        @deidentified_objects << self

        save!
      end
    end
  end

  private

  def deidentify_column(column, config)
    policy, options = Array(config)
    old_value = send(column)

    new_value = if policy.respond_to? :call
                  policy.call(old_value)
                else
                  POLICY_MAP[policy].call(old_value, **options)
                end

    write_attribute(column, new_value)
  end

  def deidentify_associations!
    associations_to_deidentify.each do |association_name|
      if collection_association?(association_name)
        send(association_name).each { |object| deidentify_object!(object) }
      else
        deidentify_object!(send(association_name))
      end
    end
  end

  def deidentify_object!(object)
    return if object.nil? || @deidentified_objects.include?(object)

    object.recursive_deidentify!(deidentified_objects: @deidentified_objects)
  end

  def collection_association?(association_name)
    self.class.reflect_on_association(association_name).collection?
  end
end
