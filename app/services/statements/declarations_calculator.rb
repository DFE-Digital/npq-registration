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
          lead_provider: statement.lead_provider,
        )

      case declaration_type
      when "started"
        Application.where(cohort: statement.cohort, lead_provider: statement.lead_provider).accepted
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
      when nil
        statement.milestone_declaration_types.map { |declaration_type| expected_applications(declaration_type) }.flatten
      else
        raise "Invalid declaration type"
      end
    end

    def received_declarations(declaration_type = nil)
      scope = statement.declarations.billable.where(cohort: statement.cohort, lead_provider: statement.lead_provider)

      if declaration_type
        scope.where(declaration_type: declaration_type)
      else
        scope.where(declaration_type: statement.milestone_declaration_types)
      end
    end
  end
end
