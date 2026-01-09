# frozen_string_literal: true

module Statements
  class DeclarationsCalculator
    class InvalidDeclarationType < StandardError; end

    attr_reader :statement

    def initialize(statement:)
      @statement = statement
    end

    def expected_applications(declaration_type)
      @expected_applications ||=
        case declaration_type
        when "started"
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

    def all_expected_applications
      @all_expected_applications ||= statement.milestone_declaration_types.map { |declaration_type| expected_applications(declaration_type) }.flatten
    end

    def received_declarations(declaration_type = nil)
      scope = statement.declarations.billable.where(cohort: statement.cohort, lead_provider: statement.lead_provider)

      if declaration_type
        scope.where(declaration_type: declaration_type)
      else
        scope.where(declaration_type: statement.milestone_declaration_types)
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
  end
end
