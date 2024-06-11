module API
  module V2
    class EnrolmentsController < BaseController
      include ::API::Concerns::FilterByUpdatedSince

      def index
        respond_to do |format|
          format.csv do
            render body: to_csv(applications_query.applications)
          end
        end
      end

    private

      def to_csv(applications)
        EnrolmentsCsvSerializer.new(applications).serialize
      end

      def applications_query
        conditions = { lead_provider: current_lead_provider, updated_since:, lead_provider_approval_status: "accepted" }

        Applications::Query.new(**conditions.compact)
      end
    end
  end
end
