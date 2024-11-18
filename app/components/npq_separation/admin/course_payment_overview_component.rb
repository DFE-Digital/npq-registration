module NpqSeparation
  module Admin
    class CoursePaymentOverviewComponent < ViewComponent::Base
      attr_reader :contract

      delegate_missing_to :calculator

      def initialize(contract:)
        @contract = contract
      end

      def calculator
        @calculator ||= ::Statements::CourseCalculator.new(contract:)
      end

      def course_name
        contract.course.name
      end

      def counts
        allowed_declaration_types.inject({}) { |m, dt|
          m.merge(dt.titleize => billable_declarations_count_for_declaration_type(dt))
        }.merge({
          t(".total_declarations") => billable_declarations_count,
          t(".total_not_eligible_for_funding") => not_eligible_declarations_count,
        })
      end

      def line_items
        [
          output_payment_row,
          *refundable_declaration_rows,
          targeted_delivery_funding_billable_row,
          targeted_delivery_funding_refundable_row,
          monthly_service_fees_row,
        ].compact
      end

    private

      def output_payment_row
        [
          t(".output_payment"),
          billable_declarations_count,
          output_payment_per_participant,
          output_payment_subtotal,
        ]
      end

      def refundable_declaration_rows
        return [] unless refundable_declarations_count.positive?

        refundable_declarations_by_type_count.map do |type, count|
          [
            "Clawbacks - #{type.humanize}",
            count,
            -output_payment_per_participant,
            -(count * output_payment_per_participant),
          ]
        end
      end

      def targeted_delivery_funding_billable_row
        return unless course_has_targeted_delivery_funding?

        [
          t(".targeted_delivery_funding"),
          targeted_delivery_funding_declarations_count,
          targeted_delivery_funding_per_participant,
          targeted_delivery_funding_subtotal,
        ]
      end

      def targeted_delivery_funding_refundable_row
        return unless course_has_targeted_delivery_funding? && targeted_delivery_funding_refundable_declarations_count.positive?

        [
          "Clawbacks",
          targeted_delivery_funding_refundable_declarations_count,
          -targeted_delivery_funding_per_participant,
          -targeted_delivery_funding_refundable_subtotal,
        ]
      end

      def monthly_service_fees_row
        return if monthly_service_fees.zero?

        [
          t(".service_fee"),
          recruitment_target,
          service_fees_per_participant,
          monthly_service_fees,
        ]
      end
    end
  end
end
