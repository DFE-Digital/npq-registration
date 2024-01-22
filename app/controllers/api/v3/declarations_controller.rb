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
          .includes(:outcomes, :statement_items, application: :course)
          .where(application: { lead_provider_id: current_lead_provider.id })
          .first(per_page) # current max limit for api is 3000

        render json: DeclarationSerializer.new(query_scope).serializable_hash
      end

      def create
        attributes = permitted_params["attributes"] || {}

        application = Application
          .includes(:user, :lead_provider)
          .where(
            user: { ecf_id: attributes[:participant_id] },
            lead_provider_id: current_lead_provider.id,
          ).first

        dec = application.declarations.create!(
          state: "eligible",
          declaration_type: attributes[:declaration_type],
          declaration_date: attributes[:declaration_date],
        )

        render json: DeclarationSerializer.new(dec).serializable_hash
      end

      def show
        dec = query_scope.find(params[:id])
        render json: DeclarationSerializer.new(dec).serializable_hash
      end

      def void
        dec = query_scope.find(params[:declaration_id])
        dec.update!(state: "voided")
        render json: DeclarationSerializer.new(dec).serializable_hash
      end

    private

      def query_scope
        Declaration
          .includes(:outcomes, :statement_items, application: :course)
          .where(application: { lead_provider_id: current_lead_provider.id })
      end

      def permitted_params
        params
          .require(:data)
          .permit(:type, attributes: %i[course_identifier declaration_date declaration_type participant_id evidence_held has_passed])
      rescue ActionController::ParameterMissing => e
        if e.param == :data
          raise ActionController::BadRequest, I18n.t(:invalid_data_structure)
        else
          raise
        end
      end
    end
  end
end
