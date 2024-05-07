# frozen_string_literal: true

module API
  module Concerns
    module Orderable
      extend ActiveSupport::Concern

      SORT_ORDER = { "+" => "ASC", "-" => "DESC" }.freeze

      def sort_order(sort:, model:, default: {})
        return default unless sort

        sort_parts = sort.split(",")
        sort_parts
          .map { |sort_part| convert_sort_part_to_active_record_order(sort_part, model) }
          .compact
          .join(", ")
          .presence
      end

    private

      def convert_sort_part_to_active_record_order(sort_part, model)
        extracted_sort_sign = sort_part =~ /\A[+-]/ ? sort_part.slice!(0) : "+"
        sort_order = SORT_ORDER[extracted_sort_sign]

        return unless sort_part.in?(model.attribute_names)

        "#{model.table_name}.#{sort_part} #{sort_order}"
      end
    end
  end
end
