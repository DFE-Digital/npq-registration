module API
  module V3
    class ParticipantOutcomesController < BaseController
      include Pagination
      include API::Concerns::FilterByDate

      def index
        render json: to_json(paginate(outcomes_query.participant_outcomes))
      end

    private

      def outcomes_query
        conditions = { lead_provider: current_lead_provider, created_since: }
        ::ParticipantOutcomes::Query.new(**conditions.compact)
      end

      def to_json(obj)
        ParticipantOutcomeSerializer.render(obj, view: :v3, root: "data")
      end
    end
  end
end