module API
  module V3
    class ParticipantsController < BaseController
      include Pagination
      include ::API::Concerns::FilterByUpdatedSince

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

      def change_schedule = head(:method_not_allowed)
      def defer = head(:method_not_allowed)
      def withdraw = head(:method_not_allowed)
      def outcomes = head(:method_not_allowed)

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
          .permit(:course_identifier)
          .merge(
            participant:,
            lead_provider: current_lead_provider,
          )
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
