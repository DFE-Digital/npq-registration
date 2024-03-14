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
        ::Statements::Query.new
                           .by_lead_provider(current_lead_provider)
                           .by_cohorts(cohorts)
      end

      def statement_params
        params.permit(:id, filter: %i[cohort])
      end

      def cohorts
        params[:filter] && params[:filter][:cohort].split(",")
      end

      def to_json(obj)
        StatementSerializer.render(obj, root: "data")
      end
    end
  end
end
