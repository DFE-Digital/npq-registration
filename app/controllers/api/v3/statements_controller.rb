module API
  module V3
    class StatementsController < BaseController
      before_action :validate_updated_since, only: %i[index]

      def index
        render json: to_json(statements_query.statements)
      end

      def show
        render json: to_json(statements_query.statement(id: statement_params[:id]))
      end

    private

      def statements_query
        Statements::Query.new(
          lead_provider: current_lead_provider,
          cohort_start_years:,
          updated_since:,
        )
      end

      def statement_params
        params.permit(:id, :cohort, filter: %i[cohort updated_since])
      end

      def cohort_start_years
        statement_params.dig(:filter, :cohort)
      end

      def updated_since
        statement_params.dig(:filter, :updated_since)
      end

      def to_json(obj)
        StatementSerializer.render(obj, root: "data")
      end

      def validate_updated_since
        return if updated_since.blank?

        Time.iso8601(URI.decode_www_form_component(updated_since))
      rescue ArgumentError
        raise ActionController::BadRequest, I18n.t(:invalid_updated_since_filter)
      end
    end
  end
end
