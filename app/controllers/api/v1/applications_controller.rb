module Api
  module V1
    class ApplicationsController < BaseController
      def index
        per_page = begin
          params["page"]["per_page"].to_i
        rescue StandardError
          30
        end

        query_scope = Application
          .includes(:course, :user, :private_childcare_provider) # :cohort is not linked atm
          .where(lead_provider: current_lead_provider)
          .first(per_page) # current max limit for api is 3000

        render json: ApplicationSerializer.new(query_scope).serializable_hash
      end

      def show = head(:method_not_allowed)
      def accept = head(:method_not_allowed)
      def reject = head(:method_not_allowed)
    end
  end
end
