# frozen_string_literal: true

module NpqSeparation
  module Admin
    class StatementSelectorComponent < BaseComponent
      attr_reader :lead_provider_id, :cohort_id, :period

      def initialize(selection)
        @lead_provider_id, @cohort_id, @period = selection.values_at(:lead_provider_id, :cohort_id, :period)
      end

      def lead_providers
        LeadProvider.all.alphabetical
      end

      def cohorts
        Cohort.all.order(:start_year)
      end

      def periods
        scope = Statement.order(:year, :month)
        scope = scope.where(lead_provider_id:) if lead_provider_id.present?
        scope = scope.where(cohort_id:) if cohort_id.present?

        [OpenStruct.new(name: "All", value: "")] + scope.uniq(&:period)
      end
    end
  end
end
