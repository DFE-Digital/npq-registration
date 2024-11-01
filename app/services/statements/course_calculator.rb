# frozen_string_literal: true

# require "payment_calculator/npq/service_fees"
# require "payment_calculator/npq/output_payment"

module Statements
  class CourseCalculator
    attr_reader :statement, :contract

    # delegate :npq_lead_provider,
    #          to: :cpd_lead_provider

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
               .where(application: { course_id: contract.course_id })
    end

    def billable_declarations_count
      # statement
      #   .billable_statement_line_items
      #   .joins(:participant_declaration)
      #   .where(participant_declarations: { course_identifier: course.identifier })
      #   .merge(ParticipantDeclaration.select("DISTINCT (user_id, declaration_type)"))
      #   .count
      statement_items
        .billable
        .joins(:declaration)
        .merge(Declaration.select("DISTINCT (application_id, declaration_type)"))
        .count
    end

    def refundable_declarations_count
      # statement
      #   .refundable_statement_line_items
      #   .joins(:participant_declaration)
      #   .where(participant_declarations: { course_identifier: course.identifier })
      #   .merge(ParticipantDeclaration.select("DISTINCT (user_id, declaration_type)"))
      #   .count
      statement_items
        .refundable
        .count
    end

    def not_eligible_declarations_count
      # statement
      #   .statement_line_items
      #   .where(statement_line_items: { state: %w[ineligible voided] })
      #   .joins(:participant_declaration)
      #   .where(participant_declarations: { course_identifier: course.identifier })
      #   .merge(ParticipantDeclaration.select("DISTINCT (user_id, declaration_type)"))
      #   .count
      statement_items
        .not_eligible
        .count
    end

    def refundable_declarations_by_type_count
      # statement
      #   .refundable_statement_line_items
      #   .joins(:participant_declaration)
      #   .where(participant_declarations: { course_identifier: course.identifier })
      #   .merge(ParticipantDeclaration.select("DISTINCT (user_id, declaration_type)"))
      #   .group(:declaration_type)
      #   .count
      statement_items
        .refundable
        # .joins(:declaration)
        # .joins(declaration: :course)
        # .where(courses: { identifier: course.identifier })
        .merge(Declaration.select("DISTINCT (application_id, declaration_type)"))
        .group(:declaration_type)
        .count
    end

    def billable_declarations_count_for_declaration_type(declaration_type)
      # scope = statement
      #   .billable_statement_line_items
      #   .joins(:participant_declaration)
      #   .where(participant_declarations: { course_identifier: course.identifier })
      #   .merge(ParticipantDeclaration.select("DISTINCT (user_id, declaration_type)"))

      # scope = if declaration_type == "retained"
      #           scope.where("participant_declarations.declaration_type LIKE ?", "retained-%")
      #         else
      #           scope.where(participant_declarations: { declaration_type: })
      #         end

      # scope.count

      scope = statement_items
        .billable
        .joins(:declaration)

      scope = if declaration_type == "retained"
                scope.where(declaration: { declaration_type: ["retained-1", "retained-2"] })
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
      course.schedule_for(cohort:).allowed_declaration_types
    end

    # def declaration_count_for_milestone(milestone)
    def declaration_count_for_declaration_type(declaration_type)
      # statement.declarations.where(declaration_type:).count

      # declaration_count_by_type.fetch(milestone.declaration_type, 0)
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
      # show_targeted_delivery_funding? &&
        # !(::Finance::Schedule::NPQEhco::IDENTIFIERS + ::Finance::Schedule::NPQSupport::IDENTIFIERS).compact.include?(course.identifier)
    end

    def targeted_delivery_funding_declarations_count
      return 0 unless course_has_targeted_delivery_funding?

      # @targeted_delivery_funding_declarations_count ||=
      #   statement
      #       .billable_statement_line_items
      #       .joins(:participant_declaration)
      #       .joins("INNER JOIN npq_applications  ON npq_applications.id = participant_declarations.participant_profile_id")
      #       .where(
      #         participant_declarations: { course_identifier: course.identifier, declaration_type: "started" },
      #         npq_applications: { targeted_delivery_funding_eligibility: true, eligible_for_funding: true },
      #       )
      #       .merge(ParticipantDeclaration.select("DISTINCT (user_id, declaration_type)"))
      #       .count

      @targeted_delivery_funding_declarations_count ||=
        statement_items
            .billable
            # .joins(declaration: :application)
            .where(
              declaration: { declaration_type: "started" },
              application: { course_id: course.id, targeted_delivery_funding_eligibility: true, eligible_for_funding: true },
            )
            .merge(Declaration.select("DISTINCT (application_id, declaration_type)"))
            .count
    end

    def targeted_delivery_funding_subtotal
      targeted_delivery_funding_per_participant * targeted_delivery_funding_declarations_count
    end

    def targeted_delivery_funding_refundable_declarations_count
      return 0 unless course_has_targeted_delivery_funding?

      # @targeted_delivery_funding_refundable_declarations_count ||=
      #   statement
      #       .refundable_statement_line_items
      #       .joins(:participant_declaration)
      #       .joins("INNER JOIN npq_applications  ON npq_applications.id = participant_declarations.participant_profile_id")
      #       .where(
      #         participant_declarations: { course_identifier: course.identifier, declaration_type: "started" },
      #         npq_applications: { targeted_delivery_funding_eligibility: true, eligible_for_funding: true },
      #       )
      #       .merge(ParticipantDeclaration.select("DISTINCT (user_id, declaration_type)"))
      #       .count

      @targeted_delivery_funding_refundable_declarations_count ||=
        statement_items
            .refundable
            # .joins(declaration: :application)
            .where(
              declaration: { declaration_type: "started" },
              application: { course_id: course.id, targeted_delivery_funding_eligibility: true, eligible_for_funding: true },
            )
            .merge(Declaration.select("DISTINCT (application_id, declaration_type)"))
            .count
    end

    def targeted_delivery_funding_refundable_subtotal
      targeted_delivery_funding_per_participant * targeted_delivery_funding_refundable_declarations_count
    end

  private

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

    delegate :service_fee_percentage, :service_fee_installments, :per_participant, to: :contract

    def service_fees
      # @service_fees ||= PaymentCalculator::NPQ::ServiceFees.call(contract:)

      @service_fees ||= begin
        per_participant_portion = service_fee_percentage.zero? ? 0 : per_participant * service_fee_percentage / (100 * service_fee_installments)
        calculated_service_fee = recruitment_target * per_participant_portion

        {
          per_participant: per_participant_portion,
          monthly: calculated_service_fee,
        }
      end
    end

    # def course
    #   @course ||= contract.npq_course
    # end

    # def declaration_count_by_type
    #   @declaration_count_by_type ||= statement
    #     .billable_statement_line_items
    #     .joins(:participant_declaration)
    #     .where(participant_declarations: { course_identifier: course.identifier })
    #     .merge(ParticipantDeclaration.select("DISTINCT (user_id, declaration_type)"))
    #     .group(:declaration_type)
    #     .count
    # end
    def declaration_count_by_type
      @declaration_count_by_type ||= statement_items
        .billable
        .joins(:declaration)
        .merge(Declaration.select("DISTINCT (application_id, declaration_type)"))
        .group(:declaration_type)
        .count
    end

    # def cpd_lead_provider
    #   statement.cpd_lead_provider
    # end
  end
end
