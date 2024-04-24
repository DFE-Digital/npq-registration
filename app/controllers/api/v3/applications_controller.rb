module API
  module V3
    class ApplicationsController < BaseController
      def index = head(:method_not_allowed)

      def show
        render json: to_json(applications_query.application(ecf_id: application_params[:ecf_id]))
      end

      def accept = head(:method_not_allowed)
      def reject = head(:method_not_allowed)

    private

      def applications_query
        Applications::Query.new(
          lead_provider: current_lead_provider,
        )
      end

      def application_params
        params.permit(:ecf_id)
      end

      def to_json(obj)
        ApplicationSerializer.render(obj, view: :v3, root: "data")
      end
    end
  end
end
