# frozen_string_literal: true

module Statements
  class SummaryCalculator
    attr_reader :statement

    delegate :show_targeted_delivery_funding?, to: :statement

    def initialize(statement:)
      @statement = statement
    end

    def total_output_payment
      course_calulators.sum(&:output_payment_subtotal)
    end

    def total_targeted_delivery_funding
      course_calulators.sum(&:targeted_delivery_funding_subtotal)
    end

    def total_service_fees
      course_calulators.sum(&:monthly_service_fees)
    end

    def clawback_payments
      course_calulators.sum(&:clawback_payment)
    end

    def total_targeted_delivery_funding_refundable
      course_calulators.sum(&:targeted_delivery_funding_refundable_subtotal)
    end

    def total_clawbacks
      clawback_payments + total_targeted_delivery_funding_refundable
    end

    def total_adjustments
      statement.adjustments.sum(&:amount)
    end

    def total_payment
      total_service_fees + total_output_payment - total_clawbacks + total_adjustments + statement.reconcile_amount + total_targeted_delivery_funding
    end

    def total_starts
      course_calulators.sum { _1.billable_declarations_count_for_declaration_type("started") }
    end

    def total_retained
      course_calulators.sum { _1.billable_declarations_count_for_declaration_type("retained") }
    end

    def total_completed
      course_calulators.sum { _1.billable_declarations_count_for_declaration_type("completed") }
    end

    def total_voided
      statement.declarations
               .joins(:application)
               .select(:user_id)
               .distinct(:user_id)
               .where(state: "voided")
               .count
    end

  private

    def course_calulators
      @course_calulators ||= contracts.map { CourseCalculator.new(contract: _1) }
    end

    def contracts
      statement.contracts
        .joins(:contract_template, :course)
        .where(contract_template: { special_course: false })
        .order("courses.identifier")
    end
  end
end
