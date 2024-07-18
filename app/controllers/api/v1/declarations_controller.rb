module API
  module V1
    class DeclarationsController < BaseController
      include Pagination
      include FilterByDate

      def index
        conditions = { updated_since:, participant_ids: }
        declarations = declarations_query(conditions:).declarations

        respond_to do |format|
          format.json do
            render json: to_json(paginate(declarations))
          end

          format.csv do
            render body: to_csv(declarations)
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

      def create
        service = Declarations::Create.new(declaration_params)

        if service.create_declaration
          render json: to_json(service.declaration)
        else
          render json: API::Errors::Response.from(service), status: :unprocessable_entity
        end
      end

    private

      def declarations_query(conditions: {})
        conditions.merge!(lead_provider: current_lead_provider)
        Declarations::Query.new(**conditions.compact)
      end

      def declaration
        declarations_query.declaration(ecf_id: params[:ecf_id])
      end

      def declaration_params
        params
          .require(:data)
          .require(:attributes)
          .permit(:participant_id, :declaration_type, :declaration_date, :course_identifier, :has_passed)
          .merge(
            lead_provider: current_lead_provider,
          )
      rescue ActionController::ParameterMissing
        raise ActionController::BadRequest, I18n.t(:invalid_data_structure)
      end

      def participant_ids
        params.dig(:filter, :participant_id)
      end

      def to_json(obj)
        DeclarationSerializer.render(obj, view: :v1, root: "data")
      end

      def to_csv(obj)
        DeclarationsCsvSerializer.new(obj, view: :v1).serialize
      end
    end
  end
end
