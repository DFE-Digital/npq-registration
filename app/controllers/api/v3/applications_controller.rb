module API
  module V3
    class ApplicationsController < BaseController
      include Pagination
      include FilterByDate
      include FilterByParticipantIds

      def index
        conditions = { cohort_start_years:, participant_ids:, updated_since:, sort: }
        applications = applications_query(conditions:).applications

        render json: to_json(paginate(applications))
      end

      def show
        render json: to_json(application)
      end

      def accept
        service = Applications::Accept.new(application:, funded_place:, schedule_identifier:)

        if service.accept
          render json: to_json(service.application)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_entity
        end
      end

      def reject
        service = Applications::Reject.new(application:)

        if service.reject
          render json: to_json(service.application)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_entity
        end
      end

      def change_funded_place
        service = Applications::ChangeFundedPlace.new(application:, funded_place:)

        if service.change
          render json: to_json(service.application)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_entity
        end
      end

    private

      def applications_query(conditions: {})
        conditions.merge!(lead_provider: current_lead_provider)
        Applications::Query.new(**conditions.compact)
      end

      def application
        applications_query.application(ecf_id: application_params[:ecf_id])
      end

      def cohort_start_years
        application_params.dig(:filter, :cohort)
      end

      def application_params
        params.permit(:ecf_id, :sort, filter: %i[cohort updated_since participant_id])
      end

      def sort
        application_params[:sort]
      end

      def to_json(obj)
        ApplicationSerializer.render(obj, view: :v3, root: "data")
      end

      def accept_permitted_params
        parameters = params
          .fetch(:data)
          .permit(:type, attributes: %i[funded_place schedule_identifier])

        return parameters if parameters["attributes"].present?

        raise ActionController::BadRequest, I18n.t(:invalid_data_structure)
      rescue ActionController::ParameterMissing
        {}
      end

      def funded_place
        accept_permitted_params.dig("attributes", "funded_place")
      end

      def schedule_identifier
        accept_permitted_params.dig("attributes", "schedule_identifier")
      end
    end
  end
end
