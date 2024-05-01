module Statements
  class Query
    include Queries::ConditionFormats

    attr_reader :scope

    def initialize(lead_provider: :ignore, cohort_start_years: :ignore, updated_since: :ignore, state: :ignore, output_fee: true)
      @scope = Statement.includes(:cohort)

      where_lead_provider_is(lead_provider)
      where_cohort_start_year_in(cohort_start_years)
      where_updated_since(updated_since)
      where_state_is(state)
      where_output_fee_is(output_fee)
    end

    def statements
      scope.order(payment_date: :asc)
    end

    def statement(id: nil, ecf_id: nil)
      return scope.find_by!(ecf_id:) if ecf_id.present?
      return scope.find(id) if id.present?

      fail(ArgumentError, "id or ecf_id needed")
    end

    def where_lead_provider_is(lead_provider)
      return if lead_provider == :ignore

      scope.merge!(Statement.where(lead_provider:))

      self
    end

    def where_cohort_start_year_in(cohort_start_years)
      return if cohort_start_years == :ignore

      scope.merge!(Statement.where(cohort: { start_year: extract_conditions(cohort_start_years) }))

      self
    end

    def where_updated_since(updated_since)
      return if updated_since == :ignore

      scope.merge!(Statement.where(updated_at: updated_since..))

      self
    end

    def where_state_is(state)
      return if state == :ignore

      scope.merge!(Statement.with_state(extract_conditions(state)))

      self
    end

    def where_output_fee_is(output_fee)
      return if output_fee == :ignore

      scope.merge!(Statement.with_output_fee(output_fee:))

      self
    end
  end
end
