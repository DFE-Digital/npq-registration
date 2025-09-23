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
      scope.order(created_at: :asc, id: :asc)
    end

    def declaration(id: nil, ecf_id: nil)
      return scope.find_by!(ecf_id:) if ecf_id.present?
      return scope.find(id) if id.present?

      fail(ArgumentError, "id or ecf_id needed")
    end

  private

    def where_lead_provider_is(lead_provider)
      return if ignore?(filter: lead_provider)

      relation = Declaration.joins(:application)
      lead_provider_scope = relation.where(lead_provider:)

      if Feature.lp_transferred_declarations_visibility?
        lead_provider_scope = lead_provider_scope.or(relation.where(application: { lead_provider: }))
      end

      scope.merge!(lead_provider_scope)
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      declarations_updated_since = Declaration.where(updated_at: updated_since..)
      scope.merge!(declarations_updated_since)
    end

    def where_participant_ids_in(participant_ids)
      return if ignore?(filter: participant_ids)

      scope.merge!(Declaration.where(user: { ecf_id: extract_conditions(participant_ids, uuids: true) }))
    end

    def where_cohort_start_year_in(cohort_start_years)
      return if ignore?(filter: cohort_start_years)

      scope.merge!(Declaration.where(cohort: { start_year: extract_conditions(cohort_start_years) }))
    end

    def all_declarations
      Declaration
        .distinct
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
