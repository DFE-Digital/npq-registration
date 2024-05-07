module API
  module V1
    class ApplicationsController < BaseController
      include Pagination
      include ::API::Concerns::FilterByUpdatedSince

      def index
        render json: to_json(paginate(applications_query.applications))
      end

      def show
        render json: to_json(applications_query.application(ecf_id: application_params[:ecf_id]))
      end

      def accept = head(:method_not_allowed)
      def reject = head(:method_not_allowed)

    private

      def applications_query
        Applications::Query.new(
          lead_provider: current_lead_provider,
          cohort_start_years:,
          updated_since:,
        )
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
    end
  end
end
