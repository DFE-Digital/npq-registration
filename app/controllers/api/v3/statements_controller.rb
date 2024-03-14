module API
  module V3
    class StatementsController < BaseController
      def index
        render json: to_json(statements_query.statements)
      end

      def show
        render json: to_json(statements_query.statement(id: statement_params[:id]))
      end

    private

      def statements_query
        Statements::Query.new
                         .by_lead_provider(current_lead_provider)
                         .by_cohorts(cohorts)
                         .since(updated_since)
      end

      def statement_params
        params.permit(:id, :cohort, filter: %i[cohort updated_since])
      end

      def cohorts
        statement_params.dig(:filter, :cohort)&.split(",")
      end

      def updated_since
        statement_params.dig(:filter, :updated_since)
      end

      def to_json(obj)
        StatementSerializer.render(obj, root: "data")
      end
    end
  end
end
