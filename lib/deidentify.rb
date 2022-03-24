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
    self.associations_to_deidentify = []

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
      self.associations_to_deidentify += associations
    end
  end

  def deidentify!
    scope = Deidentify.configuration.scope
    return self if scope && scope.call(self.class).find_by(id: id).nil?

    recursive_deidentify!(deidentified_objects: [])
  end

  protected

  def recursive_deidentify!(deidentified_objects:)
    @deidentified_objects = deidentified_objects

    return if @deidentified_objects.include?(self)

    ActiveRecord::Base.transaction do
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
                  policy.call(self)
                else
                  POLICY_MAP[policy].call(old_value, **options)
                end

    write_attribute(column, new_value)
  end

  def deidentify_associations!
    associations_to_deidentify.each do |association_name|
      association = self.class.reflect_on_association(association_name)

      if association.nil?
        raise Deidentify::Error, "undefined association #{association_name} in #{self.class.name} deidentification"
      end

      scope = Deidentify.configuration.scope
      if scope
        deidentify_associations_with_scope!(association_name, association, scope)
      else
        deidentify_associations_without_scope!(association_name, association)
      end
    end
  end

  def deidentify_associations_without_scope!(association_name, association)
    if association.collection?
      deidentify_many!(send(association_name))
    else
      deidentify_one!(send(association_name))
    end
  end

  def deidentify_associations_with_scope!(association_name, association, configuration_scope)
    if association.collection?
      class_query = class_query(association.scope, configuration_scope, send(association_name))

      deidentify_many!(class_query)
    else
      class_query = class_query(association.scope, configuration_scope, association.klass)
      # For a has_one association the foreign key is on the opposite table to a belongs_to association
      # ie. belongs_to party has a party_id on the same class as the association
      #     but, has_one party has the foreign_key on the Party class not the class containing the association
      foreign_key = association.has_one? ? :id : association.foreign_key

      deidentify_one!(class_query.find_by(id: send(foreign_key)))
    end
  end

  def class_query(association_scope, configuration_scope, klass_or_association)
    if association_scope.nil?
      configuration_scope.call(klass_or_association)
    else
      # Use both the configuration scope and the scope from the association.
      # Unfortunately the order here matters so something in the association_scope
      # will take precedence over the configuration scope.
      configuration_scope.call(klass_or_association).merge(association_scope)
    end
  end

  def deidentify_many!(records)
    records.each do |record|
      record.recursive_deidentify!(deidentified_objects: @deidentified_objects)
    end
  end

  def deidentify_one!(record)
    record&.recursive_deidentify!(deidentified_objects: @deidentified_objects)
  end
end
