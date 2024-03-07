module API
  module V3
    class StatementsController < BaseController
      def show = head(:method_not_allowed)
      def index = head(:ok)
    end
  end
end
