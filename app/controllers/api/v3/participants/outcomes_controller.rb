module API
  module V3
    module Participants
      class OutcomesController < BaseController
        include Pagination

        def index
          render json: to_json(paginate(outcomes_query.participant_outcomes))
        end

        def create = head(:method_not_allowed)

      private

        def participants_query
          ::Participants::Query.new(lead_provider: current_lead_provider)
        end

        def participant
          participants_query.participant(ecf_id: params[:ecf_id])
        end

        def outcomes_query
          conditions = { lead_provider: current_lead_provider, participant_ids: participant.ecf_id }
          ::ParticipantOutcomes::Query.new(**conditions.compact)
        end

        def to_json(obj)
          ParticipantOutcomeSerializer.render(obj, view: :v3, root: "data")
        end
      end
    end
  end
end
