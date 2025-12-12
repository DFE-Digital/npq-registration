# cohorts up to 2025 reflect production
{
  2021 => %i[npq_leadership_spring npq_leadership_autumn npq_specialist_spring npq_specialist_autumn npq_aso_december npq_aso_june npq_aso_march npq_aso_november npq_ehco_june],
  2022 => %i[npq_leadership_spring npq_leadership_autumn npq_specialist_spring npq_specialist_autumn npq_ehco_june npq_ehco_march npq_ehco_november npq_ehco_december],
  2023 => %i[npq_leadership_spring npq_leadership_autumn npq_specialist_spring npq_specialist_autumn npq_ehco_june npq_ehco_march npq_ehco_november npq_ehco_december],
  2024 => %i[npq_leadership_autumn npq_specialist_autumn npq_ehco_june npq_ehco_november npq_ehco_december],
}.each do |start_year, schedules|
  cohort = Cohort.find_by(start_year:, suffix: "a")
  schedules.each do |schedule_identifier|
    FactoryBot.build(:schedule, schedule_identifier, cohort:, change_applies_dates: false).save(validate: false)
  end
end

Cohort.where(start_year: 2025..).find_each do |cohort|
  {
    npq_ehco_december: 9,
    npq_ehco_june: 8,
    npq_ehco_march: 8,
    npq_ehco_november: 9,
    npq_leadership_autumn: 9,
    npq_leadership_spring: 8,
    npq_specialist_autumn: 9,
    npq_specialist_spring: 8,
  }.each do |schedule_identifier, policy_descriptor|
    FactoryBot.create(
      :schedule,
      schedule_identifier,
      cohort:,
      change_applies_dates: false,
      policy_descriptor: policy_descriptor + (cohort.start_year - 2025),
      acceptance_window_start: Date.new(cohort.start_year, 1, 1),
      acceptance_window_end: Date.new(cohort.start_year, 12, 1),
    )
  end
end
