module Declarations
  class Query
    include Queries::ConditionFormats
    include API::Concerns::FilterIgnorable

    attr_reader :scope, :sort

    def initialize(lead_provider: :ignore, updated_since: :ignore, participant_ids: :ignore, cohort_start_years: :ignore)
      @scope = all_declarations
      @sort = sort

      where_lead_provider_is(lead_provider)
      where_updated_since(updated_since)
      where_participant_ids_in(participant_ids)
      where_cohort_start_year_in(cohort_start_years)
    end

    def declarations
      scope.order(created_at: :asc)
    end

    def declaration(id: nil, ecf_id: nil)
      return scope.find_by!(ecf_id:) if ecf_id.present?
      return scope.find(id) if id.present?

      fail(ArgumentError, "id or ecf_id needed")
    end

  private

    def where_lead_provider_is(lead_provider)
      return if ignore?(filter: lead_provider)

      scope.merge!(Declaration.where(lead_provider:))
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      declarations_updated_since = Declaration.where(updated_at: updated_since..)
      participant_outcomes_updated_since = Declaration.where(participant_outcomes: { updated_at: updated_since.. })
      statement_items_updated_since = Declaration.where(statement_items: { updated_at: updated_since.. })
      scope.merge!(declarations_updated_since.or(participant_outcomes_updated_since).or(statement_items_updated_since))
    end

    def where_participant_ids_in(participant_ids)
      return if ignore?(filter: participant_ids)

      scope.merge!(Declaration.where(user: { ecf_id: extract_conditions(participant_ids) }))
    end

    def where_cohort_start_year_in(cohort_start_years)
      return if ignore?(filter: cohort_start_years)

      scope.merge!(Declaration.where(cohort: { start_year: extract_conditions(cohort_start_years) }))
    end

    def all_declarations
      Declaration
        .includes(
          :cohort,
          :lead_provider,
          :participant_outcomes,
          application: %i[
            user
            course
            lead_provider
          ],
          statement_items: %i[
            statement
          ],
        )
    end
  end
end
