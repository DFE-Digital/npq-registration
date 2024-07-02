module API
  module V2
    class DeclarationsController < BaseController
      include Pagination
      include FilterByDate

      def index
        respond_to do |format|
          format.json do
            render json: to_json(paginate(declarations_query.declarations))
          end

          format.csv do
            render body: to_csv(declarations_query.declarations)
          end
        end
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
        conditions = { lead_provider: current_lead_provider, updated_since:, participant_ids: }
        ::Declarations::Query.new(**conditions.compact)
      end

      def declaration
        declarations_query.declaration(ecf_id: params[:ecf_id])
      end

      def participant_ids
        params.dig(:filter, :participant_id)
      end

      def to_json(obj)
        DeclarationSerializer.render(obj, view: :v2, root: "data")
      end

      def to_csv(obj)
        DeclarationsCsvSerializer.new(obj, view: :v2).serialize
      end
    end
  end
end
