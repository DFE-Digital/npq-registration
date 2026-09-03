# frozen_string_literal: true

# Shared rules to count expected, received and remaining declarations.
#
# Two calculators use these rules: one for a single statement, and one for a
# whole lead provider and cohort up to now. They only differ in where the
# milestones and the declarations come from, so a subclass must define:
#
#   cohort
#   lead_provider
#   milestone_declaration_types  the milestones we have reached
#   declarations_scope           the declarations we count as received
class BaseDeclarationsCalculator
  class InvalidDeclarationType < StandardError; end

  def cohort
    raise NotImplementedError
  end

  def lead_provider
    raise NotImplementedError
  end

  def milestone_declaration_types
    raise NotImplementedError
  end

  def expected_applications(declaration_type)
    case declaration_type
    when "started"
      return Application.none unless milestone_declaration_types.include?("started")

      Application.where(cohort:, lead_provider:).accepted
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

  def expected_applications_count(declaration_type)
    expected_applications(declaration_type).count
  end

  def total_expected_applications
    milestone_declaration_types
      .map { |declaration_type| expected_applications_count(declaration_type) }
      .sum
  end

  def received_declarations(declaration_type = nil)
    scope = declarations_scope.billable.where(cohort:, lead_provider:)

    return scope unless declaration_type

    scope.where(declaration_type:)
  end

  def received_declarations_count(declaration_type = nil)
    received_declarations(declaration_type).count
  end

  def remaining_declarations_count(declaration_type)
    expected_count = expected_applications_count(declaration_type)

    return 0 if expected_count.zero?

    expected_count -
      received_declarations_count(declaration_type) +
      previous_milestones_remaining_count(declaration_type)
  end

  def total_remaining_declarations_count
    received_for_reached_milestones =
      milestone_declaration_types
      .map { |declaration_type| received_declarations_count(declaration_type) }
      .sum

    total_expected_applications - received_for_reached_milestones
  end

private

  def declarations_scope
    raise NotImplementedError
  end

  def active_applications
    Application
      .joins(:declarations, schedule: :milestones)
      .where(training_status: "active", cohort:, lead_provider:)
  end

  def applications_with_declarations_and_milestones(declaration_type:, milestone_declaration_type:)
    return Application.none unless milestone_declaration_types.include?(milestone_declaration_type.to_s)

    active_applications.where(
      declarations: { declaration_type: Declaration.declaration_types[declaration_type] },
      schedule: { milestones: { declaration_type: Declaration.declaration_types[milestone_declaration_type] } },
    ).distinct
  end

  def applications_in_schedules_with_declarations_and_milestones(schedules:, declaration_type:, milestone_declaration_type:)
    return Application.none unless milestone_declaration_types.include?(milestone_declaration_type.to_s)

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
      previous_remaining_count = expected_applications(previous_declaration_type).uniq.count -
        received_declarations_count(previous_declaration_type)
      previous_remaining_count.positive? ? previous_remaining_count : 0
    end
  end

  def previous_milestones(declaration_type)
    declaration_type_index = Milestone::ALL_DECLARATION_TYPES.index(declaration_type)
    return [] unless declaration_type_index.positive?

    Milestone::ALL_DECLARATION_TYPES[..(declaration_type_index - 1)]
  end
end
