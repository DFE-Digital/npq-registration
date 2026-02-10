# frozen_string_literal: true

module Statements
  class DeclarationsCalculator
    class InvalidDeclarationType < StandardError; end

    attr_reader :statement

    def initialize(statement:)
      @statement = statement
    end

    def expected_applications(declaration_type)
      case declaration_type
      when "started"
        return Application.none unless statement.milestone_declaration_types.include?("started")

        Application.where(cohort: statement.cohort, lead_provider: statement.lead_provider).accepted
      when "retained-1"
        applications_with_declarations_and_milestones(
          declaration_type: :started,
          milestone_declaration_type: :"retained-1",
        )
      when "retained-2"
        applications_with_declarations_and_milestones(
          declaration_type: :"retained-1",
          milestone_declaration_type: :"retained-2",
        )
      when "completed"
        applications_in_schedules_with_declarations_and_milestones(
          schedules: Schedule.with_retained_2_milestone,
          declaration_type: :"retained-2",
          milestone_declaration_type: :completed,
        ).or(
          applications_in_schedules_with_declarations_and_milestones(
            schedules: Schedule.without_retained_2_milestone,
            declaration_type: :"retained-1",
            milestone_declaration_type: :completed,
          ),
        ).distinct
      else
        raise InvalidDeclarationType, "Invalid declaration type: #{declaration_type}, class: #{declaration_type.class}"
      end
    end

    def total_expected_applications
      statement.milestone_declaration_types
        .map { |declaration_type| expected_applications(declaration_type).count }
        .sum
    end

    def received_declarations(declaration_type = nil)
      scope = statement.declarations.billable.where(cohort: statement.cohort, lead_provider: statement.lead_provider)

      return scope unless declaration_type

      scope.where(declaration_type: declaration_type)
    end

    def remaining_declarations_count(declaration_type)
      expected_applications_count = expected_applications(declaration_type).count

      return 0 if expected_applications_count.zero?

      expected_applications_count -
        received_declarations(declaration_type).count +
        previous_milestones_remaining_count(declaration_type)
    end

    def total_remaining_declarations_count
      received_declarations_for_milestones_on_statement =
        statement.milestone_declaration_types
        .map { |declaration_type| received_declarations(declaration_type).count }
        .sum

      total_expected_applications - received_declarations_for_milestones_on_statement
    end

    def expected_output_payment(course_calculators)
      course_calculators.sum do |course_calculator|
        course_calculator.expected_output_payment_subtotal(
          expected_eligible_applications_count_for_course(course_calculator.course),
        )
      end
    end

  private

    def active_applications
      Application
        .joins(:declarations, schedule: :milestones)
        .where(
          training_status: "active",
          cohort: statement.cohort,
          lead_provider: statement.lead_provider,
        )
    end

    def applications_with_declarations_and_milestones(declaration_type:, milestone_declaration_type:)
      active_applications.where(
        declarations: { declaration_type: Declaration.declaration_types[declaration_type] },
        schedule: { milestones: { declaration_type: Declaration.declaration_types[milestone_declaration_type] } },
      ).distinct
    end

    def applications_in_schedules_with_declarations_and_milestones(schedules:, declaration_type:, milestone_declaration_type:)
      active_applications.where(
        declarations: { declaration_type: Declaration.declaration_types[declaration_type] },
        schedule: {
          id: schedules,
          milestones: { declaration_type: Declaration.declaration_types[milestone_declaration_type] },
        },
      )
    end

    def previous_milestones_remaining_count(declaration_type)
      previous_milestones(declaration_type).sum do |previous_declaration_type|
        expected_applications(previous_declaration_type).uniq.count -
          received_declarations(previous_declaration_type).count
      end
    end

    def previous_milestones(declaration_type)
      declaration_type_index = Milestone::ALL_DECLARATION_TYPES.index(declaration_type)
      return [] unless declaration_type_index.positive?

      Milestone::ALL_DECLARATION_TYPES[..(declaration_type_index - 1)]
    end

    def expected_eligible_applications_count_for_course(course)
      @expected_eligible_applications_count_for_course ||= expected_eligible_applications.group(:course_id).count
      @expected_eligible_applications_count_for_course[course.id] || 0
    end

    def expected_eligible_applications
      remaining_and_completed_applications = statement.milestone_declaration_types.excluding("started")
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
