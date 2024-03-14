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
        ::Statements::Query.new(
          lead_provider: current_lead_provider,
        )
      end

      def statement_params
        params.permit(:id)
      end

      def to_json(obj)
        StatementSerializer.render(obj, root: "data")
      end
    end
  end
end
