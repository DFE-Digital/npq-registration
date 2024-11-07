# frozen_string_literal: true

module NpqSeparation
  module Admin
    class StatementDetailsComponent < BaseComponent
      attr_reader :statement, :calculator

      def initialize(statement:)
        @statement = statement
        # FIXME: Replace with real calculator
        @calculator = stub_calculator
      end

    private

      def stub_calculator
        OpenStruct.new(
          total_output_payment: 1.0,
          total_targeted_delivery_funding: 1.0,
          total_service_fees: 1.0,
          clawback_payments: 1.0,
          total_targeted_delivery_funding_refundable: 1.0,
          total_clawbacks: 1.0,
          total_payment: 1.0,
          total_starts: 1,
          total_retained: 1,
          total_completed: 1,
          total_voided: 1,
          show_targeted_delivery_funding?: false,
        )
      end
    end
  end
end
