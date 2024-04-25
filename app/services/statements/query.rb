module Statements
  class Query < Query
    attr_reader :lead_provider, :cohort_start_years, :updated_since, :state, :output_fee

    def initialize(lead_provider: nil, cohort_start_years: nil, updated_since: nil, state: nil, output_fee: true)
      @lead_provider = lead_provider
      @cohort_start_years = extract_conditions(cohort_start_years)
      @updated_since = updated_since
      @state = extract_conditions(state)
      @output_fee = output_fee
    end

    def statements
      scope = Statement.includes(:cohort)

      scope = scope.where(lead_provider:) if lead_provider.present?
      scope = scope.where(cohort: { start_year: cohort_start_years }) if cohort_start_years.present?
      scope = scope.where(updated_at: updated_since..) if updated_since.present?
      scope = scope.where(state:) if state.present?
      scope = scope.where(output_fee:)

      scope.order(payment_date: :asc)
    end

    def statement(id: nil, ecf_id: nil)
      return statements.find_by!(ecf_id:) if ecf_id.present?
      return statements.find(id) if id.present?

      fail(ArgumentError, "id or ecf_id needed")
    end
  end
end
