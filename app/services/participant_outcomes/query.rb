module ParticipantOutcomes
  class Query
    include API::Concerns::Orderable

    attr_reader :scope, :sort

    def initialize(lead_provider: :ignore, created_since: :ignore)
      @scope = all_participant_outcomes

      where_lead_provider_is(lead_provider)
      where_created_since(created_since)
    end

    def participant_outcomes
      scope.order(order_by)
    end

  private

    def where_lead_provider_is(lead_provider)
      return if lead_provider == :ignore

      scope.merge!(ParticipantOutcome.where(declaration: { lead_provider: }))
    end

    def where_created_since(created_since)
      return if created_since == :ignore

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