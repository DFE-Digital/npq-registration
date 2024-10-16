# frozen_string_literal: true

module Statements
  class CourseCalculator
    attr_reader :statement, :contract

    delegate :cohort, :show_targeted_delivery_funding?,
             to: :statement

    delegate :course, :recruitment_target, :targeted_delivery_funding_per_participant,
             to: :contract

    def initialize(statement:, contract:)
      @statement = statement
      @contract = contract
    end

    def statement_items
      statement.statement_items
               .joins(declaration: :application)
               .merge(Declaration.select("DISTINCT (user_id, declaration_type)"))
               .where(application: { course_id: contract.course_id })
    end

    def billable_declarations_count
      statement_items.billable.count
    end

    def refundable_declarations_count
      statement_items.refundable.count
    end

    def not_eligible_declarations_count
      statement_items.not_eligible.count
    end

    def refundable_declarations_by_type_count
      statement_items.refundable.group(:declaration_type).count
    end

    def billable_declarations_count_for_declaration_type(declaration_type)
      scope = statement_items.billable

      scope = if declaration_type == "retained"
                scope.where(declaration: { declaration_type: %w[retained-1 retained-2] })
              else
                scope.where(declaration: { declaration_type: })
              end

      scope.count
    end

    def clawback_payment
      @clawback_payment ||= Statements::OutputPaymentCalculator.call(
        contract:,
        total_participants: refundable_declarations_count,
      )[:subtotal]
    end

    def output_payment_subtotal
      output_payment[:subtotal]
    end

    def allowed_declaration_types
      course.schedule_for(cohort:).allowed_declaration_types.sort_by { Schedule::DECLARATION_TYPES.index(_1) }
    end

    def declaration_count_for_declaration_type(declaration_type)
      declaration_count_by_type.fetch(declaration_type, 0)
    end

    def output_payment
      @output_payment ||= Statements::OutputPaymentCalculator.call(
        contract:,
        total_participants: billable_declarations_count,
      )
    end

    def output_payment_per_participant
      output_payment[:per_participant]
    end

    def service_fees_per_participant
      calculated_service_fee_per_participant_derived_from_monthly_service_fee || calculated_service_fee_per_participant
    end

    def monthly_service_fees
      return calculated_service_fee if contract.monthly_service_fee.nil?

      contract.monthly_service_fee
    end

    def course_total
      monthly_service_fees + output_payment_subtotal - clawback_payment + targeted_delivery_funding_subtotal - targeted_delivery_funding_refundable_subtotal
    end

    def course_has_targeted_delivery_funding?
      show_targeted_delivery_funding? && !course.ehco? && !course.aso?
    end

    def targeted_delivery_funding_declarations_count
      return 0 unless course_has_targeted_delivery_funding?

      @targeted_delivery_funding_declarations_count ||=
        statement_items
            .billable
            .where(
              declaration: { declaration_type: "started" },
              application: { course_id: course.id, targeted_delivery_funding_eligibility: true, eligible_for_funding: true },
            )
            .count
    end

    def targeted_delivery_funding_subtotal
      targeted_delivery_funding_per_participant * targeted_delivery_funding_declarations_count
    end

    def targeted_delivery_funding_refundable_declarations_count
      return 0 unless course_has_targeted_delivery_funding?

      @targeted_delivery_funding_refundable_declarations_count ||=
        statement_items
            .refundable
            .where(
              declaration: { declaration_type: "started" },
              application: { course_id: course.id, targeted_delivery_funding_eligibility: true, eligible_for_funding: true },
            )
            .count
    end

    def targeted_delivery_funding_refundable_subtotal
      targeted_delivery_funding_per_participant * targeted_delivery_funding_refundable_declarations_count
    end

  private

    delegate :service_fee_percentage, :service_fee_installments, :per_participant, to: :contract

    def calculated_service_fee_per_participant_derived_from_monthly_service_fee
      return unless contract.monthly_service_fee

      contract.monthly_service_fee / contract.recruitment_target
    end

    def calculated_service_fee_per_participant
      service_fees[:per_participant]
    end

    def calculated_service_fee
      service_fees[:monthly]
    end

    def service_fees
      @service_fees ||= ServiceFeesCalculator.call(contract:)
    end

    def declaration_count_by_type
      @declaration_count_by_type ||= statement_items.billable.group(:declaration_type).count
    end
  end
end
