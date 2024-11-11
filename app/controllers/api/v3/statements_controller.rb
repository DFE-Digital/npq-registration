module API
  module V3
    class StatementsController < BaseController
      include Pagination
      include FilterByDate

      def index
        results = json = nil

        Rack::MiniProfiler.step("Query/paginate statements") do
          results = paginate(statements_query.statements).to_a
        end

        Rack::MiniProfiler.step("Blueprinter serialization") do
          json = to_json(results)
        end

        render json:
      end

      def show
        render json: to_json(statements_query.statement(ecf_id: statement_params[:ecf_id]))
      end

    private

      def statements_query
        conditions = { lead_provider: current_lead_provider, cohort_start_years:, updated_since: }

        Statements::Query.new(**conditions.compact)
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
