module API
  module V3
    class StatementsController < BaseController
      def index
        render json: StatementSerializer.render(statements_query.statements, root: "data")
      end

      def show
        render json: StatementSerializer.render(statements_query.statement(id: statement_params[:id]), root: "data")
      end

    private

      def statements_query
        ::Statements::Query.new(
          lead_provider: current_lead_provider,
        )
      end

      def statement_params
        params.permit(:id)
      end
    end
  end
end
