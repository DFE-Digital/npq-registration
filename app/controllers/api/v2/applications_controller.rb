module API
  module V2
    class ApplicationsController < BaseController
      include Pagination
      include FilterByDate

      def index
        conditions = { cohort_start_years:, updated_since: }
        applications = applications_query(conditions:).applications

        respond_to do |format|
          format.json do
            render json: to_json(paginate(applications))
          end

          format.csv do
            render body: to_csv(applications)
          end
        end
      end

      def show
        render json: to_json(application)
      end

      def accept
        service = Applications::Accept.new(application:, funded_place:)

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
        params.permit(:ecf_id, filter: %i[cohort updated_since])
      end

      def to_json(obj)
        ApplicationSerializer.render(obj, root: "data")
      end

      def to_csv(obj)
        ApplicationsCsvSerializer.new(obj).serialize
      end

      def accept_permitted_params
        parameters = params
          .fetch(:data)
          .permit(:type, attributes: %i[funded_place])

        return parameters if parameters["attributes"].present?

        raise ActionController::BadRequest, I18n.t(:invalid_data_structure)
      rescue ActionController::ParameterMissing
        {}
      end

      def funded_place
        accept_permitted_params.dig("attributes", "funded_place")
      end
    end
  end
end
