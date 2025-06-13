# frozen_string_literal: true

module NpqSeparation
  module Admin
    class StatementSelectorComponent < BaseComponent
      StatementOption = Struct.new(:name, :value)

      include StatementHelper

      attr_reader :lead_provider_id, :cohort_id, :selection

      def initialize(selection)
        @selection = selection
        @lead_provider_id, @cohort_id = selection.values_at(:lead_provider_id, :cohort_id)
      end

      def payment_status
        selection[:payment_status].presence
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
        selection[:statement].presence || selection.values_at(:year, :month).join("-")
      end
    end
  end
end
