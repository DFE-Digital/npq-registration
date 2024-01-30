module Api
  module V1
    class ApplicationsController < BaseController
      def index
        render status: :ok, json: { hello: "world" }.to_json
      end

      # def show = head(:method_not_allowed)
      # def accept = head(:method_not_allowed)
      # def reject = head(:method_not_allowed)
    end
  end
end
