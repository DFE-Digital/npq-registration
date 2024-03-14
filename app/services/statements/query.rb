module Statements
  class Query
    def initialize(lead_provider:, cohorts_start_years: nil, updated_since: nil)
      @lead_provider = lead_provider
      @cohorts_start_years = cohorts_start_years&.split(",")
      @updated_since = updated_since
    end

    def statements
      scope = Statement
                .includes(:cohort)
                .where(lead_provider:)

      scope = scope.where(cohort: { start_year: cohorts_start_years }) if cohorts_start_years.present?
      scope = scope.where(updated_at: updated_since..) if updated_since.present?

      scope
    end

    def statement(id:)
      statements.find(id)
    end

  private

    attr_reader :lead_provider, :cohorts_start_years, :updated_since
  end
end
