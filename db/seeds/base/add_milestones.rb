# milestones representative of production
[
  { cohort_identifier: "2024a", schedule_identifier: "npq-leadership-autumn", milestones: %w[started retained-1 retained-2 completed], milestone_dates: [[2024, 12], [2025, 7], [2026, 2], [2026, 9]] },
  { cohort_identifier: "2024a", schedule_identifier: "npq-specialist-autumn", milestones: %w[started retained-1 completed], milestone_dates: [[2024, 12], [2025, 7], [2026, 2]] },
  { cohort_identifier: "2025a", schedule_identifier: "npq-leadership-spring", milestones: %w[started retained-1 retained-2], milestone_dates: [[2025, 6], [2026, 1], [2026, 8]] },
  { cohort_identifier: "2025a", schedule_identifier: "npq-specialist-spring", milestones: %w[started retained-1], milestone_dates: [[2025, 6], [2026, 1]] },
  { cohort_identifier: "2025b", schedule_identifier: "npq-leadership-autumn", milestones: %w[started], milestone_dates: [[2026, 2]] },
  { cohort_identifier: "2025b", schedule_identifier: "npq-specialist-autumn", milestones: %w[started], milestone_dates: [[2026, 2]] },
].each do |values|
  cohort = Cohort.find_by(identifier: values[:cohort_identifier])
  schedule = Schedule.find_by(cohort:, identifier: values[:schedule_identifier])

  values[:milestones].each do |declaration_type|
    milestone = Milestone.find_or_create_by!(
      schedule:,
      declaration_type:,
    )

    milestone_date_index = values[:milestones].index(declaration_type)
    statement_year = values[:milestone_dates][milestone_date_index].first
    statement_month = values[:milestone_dates][milestone_date_index].last

    Statement.where(cohort:, year: statement_year, month: statement_month, output_fee: true).find_each do |statement|
      MilestoneStatement.find_or_create_by!(milestone:, statement:)
    end
  end
end
