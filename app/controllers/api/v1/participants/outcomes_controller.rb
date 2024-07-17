module API
  module V1
    module Participants
      class OutcomesController < BaseController
        include Pagination

        def index
          render json: to_json(paginate(outcomes_query.participant_outcomes))
        end

        def create
          service = ParticipantOutcomes::Create.new(outcome_params)

          if service.create_outcome
            render json: to_json(service.created_outcome)
          else
            render json: API::Errors::Response.from(service), status: :unprocessable_entity
          end
        end

      private

        def outcome_params
          params
            .require(:data)
            .require(:attributes)
            .permit(:course_identifier, :state, :completion_date)
            .merge(
              lead_provider: current_lead_provider,
              participant:,
            )
        rescue ActionController::ParameterMissing
          raise ActionController::BadRequest, I18n.t(:invalid_data_structure)
        end

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
          ParticipantOutcomeSerializer.render(obj, view: :v1, root: "data")
        end
      end
    end
  end
end
