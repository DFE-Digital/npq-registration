# frozen_string_literal: true

module Statements
  class DeclarationsCalculator
    attr_reader :statement

    def initialize(statement:)
      @statement = statement
    end

    def expected_applications(declaration_type = nil)
      scope =
        Application
        .joins(:declarations, schedule: :milestones)
        .where(
          training_status: "active",
          cohort: statement.cohort,
        )

      case declaration_type
      when "started"
        Application.where(cohort: statement.cohort).accepted.distinct
      when "retained-1"
        scope.where(
          declarations: { declaration_type: Declaration.declaration_types[:started] },
          schedule: { milestones: { declaration_type: Declaration.declaration_types[:"retained-1"] } },
        ).distinct
      when "retained-2"
        scope.where(
          declarations: { declaration_type: Declaration.declaration_types[:"retained-1"] },
          schedule: { milestones: { declaration_type: Declaration.declaration_types[:"retained-2"] } },
        ).distinct
      when "completed"
        scope.where(
          declarations: { declaration_type: Declaration.declaration_types[:"retained-2"] },
          schedule: {
            id: Schedule.with_retained_2_milestone,
            milestones: { declaration_type: Declaration.declaration_types[:completed] },
          },
        ).or(
          scope.where(
            declarations: { declaration_type: Declaration.declaration_types[:"retained-1"] },
            schedule: {
              id: Schedule.without_retained_2_milestone,
              milestones: { declaration_type: Declaration.declaration_types[:completed] },
            },
          ),
        ).distinct
      else
        statement.milestone_declaration_types.map { |declaration_type| expected_applications(declaration_type) }.flatten
      end
    end

    def received_declarations(declaration_type = nil)
      if declaration_type
        statement.declarations.billable.where(declaration_type: declaration_type, cohort: statement.cohort)
      else
        statement.declarations.billable.where(declaration_type: statement.milestone_declaration_types, cohort: statement.cohort)
      end
    end
  end
end
