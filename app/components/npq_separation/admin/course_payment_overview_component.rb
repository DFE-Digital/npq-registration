module NpqSeparation
  module Admin
    class CoursePaymentOverviewComponent < ViewComponent::Base
      attr_reader :statement, :contract

      def initialize(statement:, contract:)
        @statement = statement
        @contract = contract
      end

      def calculator
        @calculator ||= Statements::CourseCalculator.new(
          statement:,
          contract:,
        )
      end
    end
  end
end
