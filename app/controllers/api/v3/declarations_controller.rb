module API
  module V3
    class DeclarationsController < BaseController
      include Pagination
      include ::API::Concerns::FilterByUpdatedSince

      def index
        render json: to_json(paginate(declarations_query.declarations))
      end

      def show
        render json: to_json(declaration)
      end

      def void
        service = Declarations::Void.new(declaration:)

        if service.void
          render json: to_json(service.declaration)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_entity
        end
      end

      def create = head(:method_not_allowed)

    private

      def declarations_query
        conditions = { lead_provider: current_lead_provider, updated_since:, participant_ids:, cohort_start_years: }
        ::Declarations::Query.new(**conditions.compact)
      end

      def declaration
        declarations_query.declaration(ecf_id: params[:ecf_id])
      end

      def participant_ids
        params.dig(:filter, :participant_id)
      end

      def cohort_start_years
        params.dig(:filter, :cohort)
      end

      def to_json(obj)
        DeclarationSerializer.render(obj, view: :v3, root: "data")
      end
    end
  end
end
