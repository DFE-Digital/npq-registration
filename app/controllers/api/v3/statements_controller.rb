module API
  module V3
    class StatementsController < BaseController
      def show
        @statement = Statement.find(params[:id])

        if @statement
          render @statement
        else
          render partial: '/api/common/not_found', status: :not_found
        end

      end

      def index
        @statements = Statements::FilterService.new(params).find_all

        render @statements
      end
    end
  end
end
