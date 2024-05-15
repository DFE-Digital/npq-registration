module API
  module V3
    class ApplicationsController < BaseController
      include Pagination
      include ::API::Concerns::FilterByUpdatedSince
      include ::API::Concerns::FilterByCreatedSince

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
        conditions = { lead_provider: current_lead_provider, cohort_start_years:, participant_ids:, updated_since:, created_since: }

        Applications::Query.new(**conditions.compact, sort: application_params[:sort])
      end

      def cohort_start_years
        application_params.dig(:filter, :cohort)
      end

      def participant_ids
        application_params.dig(:filter, :participant_id)
      end

      def application_params
        params.permit(:ecf_id, :sort, filter: %i[cohort updated_since participant_id created_since])
      end

      def to_json(obj)
        ApplicationSerializer.render(obj, view: :v3, root: "data")
      end
    end
  end
end
