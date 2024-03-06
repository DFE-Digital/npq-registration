module Statements
  class StatementsQuery
    def initialize(lead_provider:, params:)
      @lead_provider = lead_provider
      @cohorts = String(params[:cohort]).split(",")
      @update_since = params[:updated_since]
    end

    def statements
      statements = Statement.includes(:cohort).where(lead_provider:)
      statements = statements.where(cohorts: { start_year: cohorts }) if cohorts.any?

      statements
    end

    def statement; end

  private

    attr_reader \
      :lead_provider,
      :cohorts,
      :update_since
  end
end
