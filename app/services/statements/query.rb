module Statements
  class Query
    def initialize(lead_provider: nil, cohort_start_years: nil, updated_since: nil)
      @lead_provider = lead_provider
      @cohort_start_years = cohort_start_years&.split(",")
      @updated_since = updated_since
    end

    def statements
      scope = Statement
                .includes(:cohort)
                .with_output_fee

      scope = scope.where(lead_provider:) if lead_provider.present?
      scope = scope.where(cohort: { start_year: cohort_start_years }) if cohort_start_years.present?
      scope = scope.where(updated_at: updated_since..) if updated_since.present?

      scope.order(payment_date: :asc)
    end

    def statement(id: nil, ecf_id: nil)
      return statements.find_by!(ecf_id:) if ecf_id.present?
      return statements.find(id) if id.present?

  private

    attr_reader :lead_provider, :cohort_start_years, :updated_since
      fail(ArgumentError, "id or ecf_id needed")
    end
  end
end
