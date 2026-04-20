# frozen_string_literal: true

RSpec.shared_context "with cohorts", shared_context: :metadata do
  before(:context) do
    # create current cohort
    current_cohort = FactoryBot.create(:cohort, :current)

    # create course cohort providers for the next cohort
    file_name = "db/seeds/data/default_course_cohort_providers.csv"
    CourseCohortProviders::Updater.new(cohort: current_cohort, course_to_provider_csv: file_name, dry_run: false).call

    next_cohort_year = Date.current.month < 9 ? Date.current.year : Date.current.year.succ # equivalent to `:cohort, :next`

    # create an unfunded cohort for the next cohort
    FactoryBot.create(:cohort, :unfunded, start_year: next_cohort_year)

    # create a capped 'b' cohort for the next cohort
    FactoryBot.create(:cohort, start_year: next_cohort_year, suffix: "b")

    # create course cohort providers for the next capped cohort
    file_name = "db/seeds/data/default_course_cohort_providers.csv"
    CourseCohortProviders::Updater.new(cohort: Cohort.find_by(identifier: "#{next_cohort_year}b"), course_to_provider_csv: file_name, dry_run: false).call
  end

  after(:context) do
    Cohort.destroy_all
  end
end

RSpec.configure do |config|
  config.include_context "with cohorts", :with_cohorts
end
