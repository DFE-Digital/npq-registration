# cohorts up to 2025 reflect production
{
  2021 => %i[npq_leadership_spring npq_leadership_autumn npq_specialist_spring npq_specialist_autumn npq_aso_december npq_aso_june npq_aso_march npq_aso_november npq_ehco_june],
  2022 => %i[npq_leadership_spring npq_leadership_autumn npq_specialist_spring npq_specialist_autumn npq_ehco_june npq_ehco_march npq_ehco_november npq_ehco_december],
  2023 => %i[npq_leadership_spring npq_leadership_autumn npq_specialist_spring npq_specialist_autumn npq_ehco_june npq_ehco_march npq_ehco_november npq_ehco_december],
  2024 => %i[npq_leadership_autumn npq_specialist_autumn npq_ehco_june npq_ehco_november npq_ehco_december],
}.each do |start_year, schedules|
  cohort = Cohort.find_by(start_year:, suffix: "a")
  schedules.each do |schedule_identifier|
    FactoryBot.create(:schedule, schedule_identifier, cohort:, change_applies_dates: false)
  end
end

Cohort.where(start_year: 2025.., suffix: "a").find_each do |cohort|
  %i[
    npq_ehco_december
    npq_ehco_june
    npq_ehco_march
    npq_ehco_november
    npq_leadership_autumn
    npq_leadership_spring
    npq_specialist_autumn
    npq_specialist_spring
  ].each do |schedule_identifier|
    FactoryBot.create(:schedule, schedule_identifier, cohort:, change_applies_dates: false)
  end
end

Cohort.where(start_year: 2025, suffix: "b").find_each do |cohort|
  %i[
    npq_ehco_december
    npq_ehco_november
    npq_leadership_autumn
    npq_specialist_autumn
  ].each do |schedule_identifier|
    FactoryBot.create(:schedule, schedule_identifier, cohort:, change_applies_dates: false)
  end
end
