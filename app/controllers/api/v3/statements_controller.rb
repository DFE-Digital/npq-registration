module API
  module V3
    class StatementsController < BaseController
      def show = head(:method_not_allowed)

      def index
        @statements = Statement.includes(:cohort).all
        # render json: API::V3::StatementSerializer.render(@statements)
      end
    end
  end
end
