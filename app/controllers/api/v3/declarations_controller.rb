module Api
  module V3
    class DeclarationsController < BaseController
      def index
        per_page = begin
          params["page"]["per_page"].to_i
        rescue StandardError
          30
        end

        query_scope = Declaration
          .includes(:outcomes, application: :course)
          .where(application: { lead_provider_id: current_lead_provider.id })
          .first(per_page) # current max limit for api is 3000

        render json: DeclarationSerializer.new(query_scope).serializable_hash
      end

      def create = head(:method_not_allowed)
      def show = head(:method_not_allowed)
      def void = head(:method_not_allowed)
    end
  end
end
