module API
  module V2
    class ApplicationsController < BaseController
      def index = head(:method_not_allowed)
      def show = head(:method_not_allowed)
      def accept = head(:method_not_allowed)
      def reject = head(:method_not_allowed)
    end
  end
end
