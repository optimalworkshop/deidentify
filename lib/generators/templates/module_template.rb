# frozen_string_literal: true

module Deidentify::<%= namespace_model %>
  extend ActiveSupport::Concern
  include Deidentify

  included do
<% model.constantize.column_names.each do |name| -%>
    deidentify :<%= name %>, method: :keep
<% end -%>
  end
end
