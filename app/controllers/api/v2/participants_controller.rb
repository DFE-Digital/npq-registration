module API
  module V2
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

      def change_schedule
        service = ::Participants::ChangeSchedule.new(participant_action_params)

        if service.change_schedule
          render json: to_json(service.participant)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_entity
        end
      end

      def outcomes = head(:method_not_allowed)

    private

      def participants_query
        conditions = { lead_provider: current_lead_provider, updated_since: }

        ::Participants::Query.new(**conditions.compact)
      end

      def participant_params
        params.permit(:ecf_id)
      end

      def participant_action_params
        params
          .require(:data)
          .require(:attributes)
          .permit(:course_identifier, :reason, :schedule_identifier, :cohort)
          .merge(
            participant:,
            lead_provider: current_lead_provider,
          )
      rescue ActionController::ParameterMissing
        raise ActionController::BadRequest, I18n.t(:invalid_data_structure)
      end

      def to_json(obj)
        ParticipantSerializer.render(obj, view: :v2, root: "data", lead_provider: current_lead_provider)
      end

      def participant
        participants_query.participant(ecf_id: participant_params[:ecf_id])
      end
    end
  end
end
