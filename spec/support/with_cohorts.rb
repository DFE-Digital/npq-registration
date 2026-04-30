# frozen_string_literal: true

RSpec.shared_context "with cohorts", shared_context: :metadata do
  before do
    # create an unfunded cohort for the next cohort
    unfunded_cohort = FactoryBot.create(:cohort, :unfunded, :next)

    # create a capped 'b' cohort for the next cohort
    capped_cohort = FactoryBot.create(:cohort, start_year: unfunded_cohort.start_year, suffix: "b")

    # create small set of course cohort providers for the next capped cohort
    cohort = Cohort.find_by(identifier: "#{capped_cohort.start_year}b")

    provider_teach_first = LeadProvider.find_by(name: "Teach First")
    FactoryBot.create(:course_cohort, :with_provider, course: create(:course, :headship), cohort:, lead_provider: provider_teach_first)
    senior_leadership_course = create(:course, :senior_leadership)
    senior_leadership_course_cohort = FactoryBot.create(:course_cohort, :with_provider, course: senior_leadership_course, cohort:, lead_provider: provider_teach_first)
    FactoryBot.create(:course_cohort, :with_provider, course: create(:course, :early_headship_coaching_offer), cohort:, lead_provider: provider_teach_first)
    FactoryBot.create(:course_cohort, :with_provider, course: create(:course, :early_years_leadership), cohort:, lead_provider: provider_teach_first)
    FactoryBot.create(:course_cohort, :with_provider, course: create(:course, :leading_teaching), cohort:, lead_provider: provider_teach_first)

    provider_church_of_england = LeadProvider.find_by(name: "Church of England")
    FactoryBot.create(:course_cohort_provider, course_cohort: senior_leadership_course_cohort, lead_provider: provider_church_of_england)
    FactoryBot.create(:course_cohort, :with_provider, course: create(:course, :leading_teaching_development), cohort:, lead_provider: provider_church_of_england)
    FactoryBot.create(:course_cohort, :with_provider, course: create(:course, :leading_primary_mathematics), cohort:, lead_provider: provider_church_of_england)
  end
end

RSpec.configure do |config|
  config.include_context "with cohorts", :with_cohorts
end
