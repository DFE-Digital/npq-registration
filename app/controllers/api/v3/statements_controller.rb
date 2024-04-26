module API
  module V3
    class StatementsController < BaseController
      include Pagination
      include ::API::Concerns::FilterByUpdatedSince

      def index
        render json: to_json(paginate(statements_query.statements))
      end

      def show
        render json: to_json(statements_query.statement(ecf_id: statement_params[:ecf_id]))
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
        params.permit(:ecf_id, filter: %i[cohort updated_since])
      end

      def cohort_start_years
        statement_params.dig(:filter, :cohort)
      end

      def to_json(obj)
        StatementSerializer.render(obj, root: "data")
      end
    end
  end
end
