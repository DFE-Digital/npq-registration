module API
  module V2
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

      def participants_query
        conditions = { lead_provider: current_lead_provider, updated_since: }

        ::Participants::Query.new(**conditions.compact)
      end

      def participant_params
        params.permit(filter: %i[updated_since])
      end

      def to_json(obj)
        ParticipantSerializer.render(obj, view: :v2, root: "data", lead_provider: current_lead_provider)
      end
    end
  end
end
