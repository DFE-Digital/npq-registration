module API
  module V2
    class ApplicationsController < BaseController
      def index = head(:method_not_allowed)

      def show
        render json: to_json(applications_query.application(id: application_params[:id]))
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
        params.permit(:id)
      end

      def to_json(obj)
        ApplicationSerializer.render(obj, root: "data")
      end
    end
  end
end
