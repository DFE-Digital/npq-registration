# frozen_string_literal: true

RSpec.shared_context "with default schedules", shared_context: :metadata do
  before do
    # create cohorts since 2021 with default schedule
    end_year = Date.current.month < 9 ? Date.current.year : Date.current.year.succ
    (2021..end_year).each do |start_year|
      cohort = FactoryBot.create(:cohort, start_year:)
      %i[
        npq_aso_december
        npq_aso_june
        npq_aso_march
        npq_aso_november
        npq_ehco_june
        npq_ehco_march
        npq_ehco_november
        npq_ehco_december
        npq_leadership_spring
        npq_leadership_autumn
        npq_specialist_spring
        npq_specialist_autumn
      ].each do |schedule_identifier|
        FactoryBot.create(:schedule, schedule_identifier, cohort:)
      end
    end
  end
end

RSpec.configure do |config|
  config.include_context "with default schedules", :with_default_schedules
end
