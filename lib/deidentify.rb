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

  def deidentify!(validate: true)
    scope = Deidentify.configuration.scope
    return self if scope && scope.call(self.class).find_by(id: id).nil?

    recursive_deidentify!(validate: validate, deidentified_objects: [])
  end

  def deidentify_attributes
    deidentify_configuration.each_pair do |col, config|
      deidentify_column(col, config)
    end
  end

  protected

  def recursive_deidentify!(validate:, deidentified_objects:)
    @validate = validate
    @deidentified_objects = deidentified_objects

    return if @deidentified_objects.include?(self)

    ActiveRecord::Base.transaction do
      run_callbacks(:deidentify) do
        deidentify_attributes

        write_attribute(:deidentified_at, Time.current) if respond_to?(:deidentified_at)

        @deidentified_objects << self

        save!(validate: validate)
      end
    end
  end

  private

  def deidentify_column(column, config)
    unless column_exists?(column)
      Rails.logger.error "ERROR: Deidentification policy defined for #{column} but column doesn't exist"
      return
    end

    policy, options = Array(config)
    old_value = read_attribute(column)

    new_value = if policy.respond_to? :call
                  policy.call(self)
                else
                  POLICY_MAP[policy].call(old_value, **options)
                end

    write_attribute(column, new_value)
  end

  def column_exists?(column)
    self.class.columns.map(&:name).include?(column.to_s)
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
      # eg. has_many :bubbles, -> { popped }
      # This will call configuration_scope.call(self.bubbles).merge(popped)
      class_query = class_query(association.scope, configuration_scope, send(association_name))

      deidentify_many!(class_query)
    else
      class_query = class_query(association.scope, configuration_scope, association.klass)

      if association.has_one?
        # eg. (bubble) has_one :party, -> { birthday }
        # This will call configuration_scope.call(Party).merge(birthday).find_by(bubble_id: id)
        deidentify_one!(class_query.find_by("#{association.foreign_key} = #{send(:id)}"))
      else
        # eg. belongs_to :party, -> { birthday }
        # This will call configuration_scope.call(Party).merge(birthday).find_by(id: party_id)
        deidentify_one!(class_query.find_by(id: send(association.foreign_key)))
      end
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
      record.recursive_deidentify!(validate: @validate, deidentified_objects: @deidentified_objects)
    end
  end

  def deidentify_one!(record)
    record&.recursive_deidentify!(validate: @validate, deidentified_objects: @deidentified_objects)
  end
end
