module API
  module V3
    class ApplicationsController < V1::ApplicationsController
      def index
        render json: to_json(paginate(applications_query.applications))
      end

    private

      def applications_query
        conditions = { lead_provider: current_lead_provider, cohort_start_years:, participant_ids:, updated_since: }

        Applications::Query.new(**conditions.compact, sort: application_params[:sort])
      end

      def participant_ids
        application_params.dig(:filter, :participant_id)
      end

      def application_params
        params.permit(:ecf_id, :sort, filter: %i[cohort updated_since participant_id])
      end

      def to_json(obj)
        ApplicationSerializer.render(obj, view: :v3, root: "data")
      end
    end
  end
end
