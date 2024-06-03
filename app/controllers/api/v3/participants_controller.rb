module API
  module V3
    class ParticipantsController < BaseController
      include Pagination
      include ::API::Concerns::FilterByUpdatedSince

      def index
        render json: to_json(paginate(participants_query.participants))
      end

      def show = head(:method_not_allowed)
      def change_schedule = head(:method_not_allowed)
      def defer = head(:method_not_allowed)
      def withdraw = head(:method_not_allowed)
      def resume = head(:method_not_allowed)
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
        params.permit(:sort, filter: %i[updated_since training_status from_participant_id])
      end

      def to_json(obj)
        ParticipantSerializer.render(obj, view: :v3, root: "data", lead_provider: current_lead_provider)
      end
    end
  end
end
