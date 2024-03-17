module Statements
  class Query
    def initialize(lead_provider:, cohort_start_years: nil, updated_since: nil)
      @lead_provider = lead_provider
      @cohort_start_years = cohort_start_years&.split(",")
      @updated_since = updated_since
    end

    def statements
      scope = Statement
                .includes(:cohort)
                .where(lead_provider:)
                .with_output_fee

      scope = scope.where(cohort: { start_year: cohort_start_years }) if cohort_start_years.present?
      scope = scope.where(updated_at: updated_since..) if updated_since.present?

      scope.order(payment_date: :asc)
    end

    def statement(id:)
      statements.find(id)
    end

  private

    attr_reader :lead_provider, :cohort_start_years, :updated_since
  end
end
