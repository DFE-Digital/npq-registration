module Statements
  class Query
    include Queries::ConditionFormats
    include API::Concerns::FilterIgnorable

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

  private

    def where_lead_provider_is(lead_provider)
      return if ignore?(filter: lead_provider)

      scope.merge!(Statement.where(lead_provider:))
    end

    def where_cohort_start_year_in(cohort_start_years)
      return if ignore?(filter: cohort_start_years)

      scope.merge!(Statement.where(cohort: { start_year: extract_conditions(cohort_start_years) }))
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      scope.merge!(Statement.where(updated_at: updated_since..))
    end

    def where_state_is(state)
      return if ignore?(filter: state)

      scope.merge!(Statement.with_state(extract_conditions(state)))
    end

    def where_output_fee_is(output_fee)
      return if ignore?(filter: output_fee)

      scope.merge!(Statement.with_output_fee(output_fee:))
    end
  end
end
