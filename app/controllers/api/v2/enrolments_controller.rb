module API
  module V2
    class EnrolmentsController < BaseController
      include FilterByDate

      def index
        conditions = { updated_since:, lead_provider_approval_status: "accepted" }
        applications = applications_query(conditions:).applications

        respond_to do |format|
          format.csv do
            render body: to_csv(applications)
          end
        end
      end

    private

      def to_csv(applications)
        EnrolmentsCsvSerializer.new(applications).serialize
      end

      def applications_query(conditions: {})
        conditions.merge!(lead_provider: current_lead_provider)
        Applications::Query.new(**conditions.compact)
      end
    end
  end
end
