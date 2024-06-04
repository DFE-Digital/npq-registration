Cohort.find_each do |cohort|
  %i[
    npq_aso_december
    npq_aso_june
    npq_aso_march
    npq_aso_november
    npq_ehco_december
    npq_ehco_june
    npq_ehco_march
    npq_ehco_november
    npq_leadership_autumn
    npq_leadership_spring
    npq_specialist_autumn
    npq_specialist_spring
  ].each do |schedule_identifier|
    FactoryBot.create(:schedule, schedule_identifier, cohort:)
  end
end
