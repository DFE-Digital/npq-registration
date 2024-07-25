module ParticipantOutcomes
  class Query
    include API::Concerns::Orderable
    include Queries::ConditionFormats
    include API::Concerns::FilterIgnorable

    attr_reader :scope, :sort

    def initialize(lead_provider: :ignore, participant_ids: :ignore, created_since: :ignore)
      @scope = all_participant_outcomes

      where_participant_ids_in(participant_ids)
      where_lead_provider_is(lead_provider)
      where_created_since(created_since)
    end

    def participant_outcomes
      scope.order(order_by)
    end

  private

    def where_lead_provider_is(lead_provider)
      return if ignore?(filter: lead_provider)

      scope.merge!(ParticipantOutcome.where(declaration: { lead_provider: }))
    end

    def where_participant_ids_in(participant_ids)
      return if ignore?(filter: participant_ids)

      scope.merge!(ParticipantOutcome.where(user: { ecf_id: extract_conditions(participant_ids) }))
    end

    def where_created_since(created_since)
      return if ignore?(filter: created_since)

      scope.merge!(ParticipantOutcome.where(created_at: created_since..))
    end

    def order_by
      sort_order(sort:, model: ParticipantOutcome, default: { created_at: :asc })
    end

    def all_participant_outcomes
      ParticipantOutcome.includes(
        declaration: {
          lead_provider: {},
          application: %i[course user],
        },
      )
    end
  end
end
