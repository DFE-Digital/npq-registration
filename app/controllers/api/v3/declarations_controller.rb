module API
  module V3
    class DeclarationsController < BaseController
      include Pagination
      include FilterByDate
      include FilterByParticipantIds

      before_action :ensure_declaration_belongs_to_lead_provider, except: %i[index show create]

      def index
        conditions = { updated_since:, participant_ids:, cohort_start_years: }
        declarations = declarations_query(conditions:).declarations
                         .includes(:delivery_partner, :secondary_delivery_partner)

        render json: to_json(paginate(declarations))
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

      def change_delivery_partner
        service = Declarations::ChangeDeliveryPartner.new(declaration:, delivery_partner_id:, secondary_delivery_partner_id:)

        if service.change_delivery_partner
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
          .permit(:participant_id,
                  :declaration_type,
                  :declaration_date,
                  :course_identifier,
                  :has_passed,
                  :delivery_partner_id,
                  :secondary_delivery_partner_id)
          .merge(
            lead_provider: current_lead_provider,
          )
      rescue ActionController::ParameterMissing
        raise ActionController::BadRequest, I18n.t(:invalid_data_structure)
      end

      def change_delivery_partner_params
        params
          .require(:data)
          .require(:attributes)
          .permit(:delivery_partner_id,
                  :secondary_delivery_partner_id)
          .merge(
            lead_provider: current_lead_provider,
          )
      rescue ActionController::ParameterMissing
        raise ActionController::BadRequest, I18n.t(:invalid_data_structure)
      end

      def cohort_start_years
        params.dig(:filter, :cohort)
      end

      def to_json(obj)
        DeclarationSerializer.render(obj, view: :v3, root: "data")
      end

      def delivery_partner_id
        change_delivery_partner_params["delivery_partner_id"]
      end

      def secondary_delivery_partner_id
        change_delivery_partner_params["secondary_delivery_partner_id"]
      end

      def ensure_declaration_belongs_to_lead_provider
        return if declaration.lead_provider == current_lead_provider

        errors = [{
          title: "Cannot modify declaration",
          detail: "The declaration cannot be modified because it was created by another lead provider",
        }]

        render json: { errors: }, status: :forbidden
      end
    end
  end
end
