# frozen_string_literal: true

module Statements
  class DeclarationsCalculator < BaseDeclarationsCalculator
    attr_reader :statement

    delegate :cohort, :lead_provider, :milestone_declaration_types, to: :statement

    def initialize(statement:)
      @statement = statement
      super()
    end

    def expected_output_payment(course_calculators)
      course_calculators.sum do |course_calculator|
        course_calculator.expected_output_payment_subtotal(
          expected_eligible_applications_count_for_course(course_calculator.course),
        )
      end
    end

  private

    def declarations_scope
      statement.declarations
    end

    def expected_eligible_applications_count_for_course(course)
      @expected_eligible_applications_count_for_course ||= expected_eligible_applications.group(:course_id).count
      @expected_eligible_applications_count_for_course[course.id] || 0
    end

    def expected_eligible_applications
      remaining_and_completed_applications = milestone_declaration_types.excluding("started")
        .map { |declaration_type| expected_applications(declaration_type) }
        .reduce(:or) || Application.none
      started_applications = expected_applications("started")
      # can't combine the above scopes directly due to different joins (the relations are structurally incompatible)
      # so need to use an Arel union
      union = Arel::Nodes::Union.new(remaining_and_completed_applications.arel, started_applications.arel)
      Application.from(Arel::Nodes::TableAlias.new(union, Application.table_name))
    end
  end
end
