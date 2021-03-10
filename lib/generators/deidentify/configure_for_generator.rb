require 'rails/generators'
module Deidentify
  module Generators
    class ConfigureForGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __dir__)

      argument :model, type: :string, banner: "model name"
      class_option :file_path, type: :string, default: ""

      def call
        template "module_template.rb", File.join(module_path,  "#{klass.underscore}.rb")

        insert_into_file(
          model_path,
          "\n  include Deidentify::#{namespace_model}",
          after: "#{klass} < ApplicationRecord"
        )
      end

      private

      def namespace_model
        if file_path.present?
          file_path.split("/").map(&:camelcase).join("::")
        else
          model
        end
      end

      def model_path
        path = if file_path.present?
          file_path
        else
          full_path.map(&:underscore).join('/')
        end

        "app/models/#{path}.rb"
      end

      def module_path
        path = if file_path.present?
          file_path.split("/")
        else
          full_path.map(&:underscore)
        end

        path = path[0...-1].join("/") #remove the class name

        "app/concerns/deidentify/#{path}"
      end

      def klass
        full_path.last
      end

      def full_path
        @full_path ||= model.split("::")
      end

      def file_path
        options['file_path'].split(".").first #remove the .rb if it exists
      end
    end
  end
end
