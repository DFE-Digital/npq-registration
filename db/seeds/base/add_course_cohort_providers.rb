defaults_csv = "db/seeds/data/default_course_cohort_providers.csv"
current_cohort_start_year = Date.current.month < 9 ? (Date.current.year - 1) : Date.current.year

(2021..current_cohort_start_year).each do |start_year|
  cohort = Cohort.find_by(start_year:)
  CourseCohortProviders::Updater.new(cohort:, course_to_provider_csv: defaults_csv, dry_run: false).call
end

next_cohort_year = current_cohort_start_year + 1
unfunded_csv = "db/seeds/data/unfunded_spring_2026a_course_cohort_providers.csv"
unfunded_cohort = Cohort.find_by(identifier: "#{next_cohort_year}a")
capped_cohort = Cohort.find_by(identifier: "#{next_cohort_year}b")
CourseCohortProviders::Updater.new(cohort: unfunded_cohort, course_to_provider_csv: unfunded_csv, dry_run: false).call
CourseCohortProviders::Updater.new(cohort: capped_cohort, course_to_provider_csv: defaults_csv, dry_run: false).call
