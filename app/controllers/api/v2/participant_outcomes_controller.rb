module API
  module V2
    class ParticipantOutcomesController < BaseController
      include Pagination
      include FilterByDate

      def index
        conditions = { created_since: }
        outcomes = outcomes_query(conditions:).participant_outcomes

        render json: to_json(paginate(outcomes))
      end

    private

      def outcomes_query(conditions: {})
        conditions.merge!(lead_provider: current_lead_provider)
        ParticipantOutcomes::Query.new(**conditions.compact)
      end

      def to_json(obj)
        ParticipantOutcomeSerializer.render(obj, view: :v2, root: "data")
      end
    end
  end
end
