module API
  module V1
    class ApplicationsController < BaseController
      include Pagination
      include ::API::Concerns::FilterByUpdatedSince

      def index
        respond_to do |format|
          format.json do
            render json: to_json(paginate(applications_query.applications))
          end

          format.csv do
            render body: to_csv(applications_query.applications)
          end
        end
      end

      def show
        render json: to_json(application)
      end

      def accept = head(:method_not_allowed)

      def reject
        service = Applications::Reject.new(application:)

        render_from_service(service)
      end

    private

      def applications_query
        conditions = { lead_provider: current_lead_provider, cohort_start_years:, updated_since: }

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
        ApplicationCsvSerializer.new(obj).call
      end
    end
  end
end
