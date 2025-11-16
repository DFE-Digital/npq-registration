# frozen_string_literal: true

module NpqSeparation
  module Admin
    class StatementSelectorComponent < BaseComponent
      StatementOption = Struct.new(:name, :value)

      include StatementHelper

      attr_reader :cohort_id, :format_for_sidebar, :lead_provider_id, :selection

      def initialize(selection, format_for_sidebar: false)
        @selection = selection
        @lead_provider_id, @cohort_id = selection.values_at(:lead_provider_id, :cohort_id)
        @format_for_sidebar = format_for_sidebar
      end

      def grid_column_class
        format_for_sidebar ? "govuk-grid-column-full" : "govuk-grid-column-one-half"
      end

      def submit_button_text
        format_for_sidebar ? "View" : "Search"
      end

      def payment_status
        selection[:payment_status].presence
      end

      def output_fee
        selection.key?(:output_fee) ? selection[:output_fee] : "true"
      end

      def lead_providers
        LeadProvider.all.alphabetical
      end

      def cohorts
        Cohort.all.order(:start_year)
      end

      def statements
        scope = Statement.order(:year, :month)
        scope = scope.where(lead_provider_id:) if lead_provider_id.present?
        scope = scope.where(cohort_id:) if cohort_id.present?

        options = [["All", ""]] + scope.map { [statement_name(_1), statement_period(_1)] }
        options.map { StatementOption.new(*_1) }.uniq(&:value)
      end

      def selected_statement
        selection[:statement].presence
      end
    end
  end
end
