module API
  module V3
    class ParticipantsController < BaseController
      include Pagination
      include FilterByDate

      def index
        render json: to_json(paginate(participants_query.participants))
      end

      def show
        render json: to_json(participant)
      end

      def resume
        service = ::Participants::Resume.new(participant_action_params)

        if service.resume
          render json: to_json(service.participant)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_entity
        end
      end

      def defer
        service = ::Participants::Defer.new(participant_action_params)

        if service.defer
          render json: to_json(service.participant)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_entity
        end
      end

      def withdraw
        service = ::Participants::Withdraw.new(participant_action_params)

        if service.withdraw
          render json: to_json(service.participant)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_entity
        end
      end

      def change_schedule = head(:method_not_allowed)

    private

      def training_status
        participant_params.dig(:filter, :training_status)
      end

      def from_participant_id
        participant_params.dig(:filter, :from_participant_id)
      end

      def participants_query
        conditions = { lead_provider: current_lead_provider, updated_since:, training_status:, from_participant_id: }

        ::Participants::Query.new(**conditions.compact)
      end

      def participant_params
        params.permit(:ecf_id, filter: %i[training_status from_participant_id])
      end

      def participant_action_params
        params
          .require(:data)
          .require(:attributes)
          .permit(:course_identifier, :reason)
          .merge(
            participant:,
            lead_provider: current_lead_provider,
          )
      rescue ActionController::ParameterMissing
        raise ActionController::BadRequest, I18n.t(:invalid_data_structure)
      end

      def to_json(obj)
        ParticipantSerializer.render(obj, view: :v3, root: "data", lead_provider: current_lead_provider)
      end

      def participant
        participants_query.participant(ecf_id: participant_params[:ecf_id])
      end
    end
  end
end
