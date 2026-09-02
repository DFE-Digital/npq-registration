defaults_csv = "db/seeds/data/default_course_cohort_providers.csv"

(2021..Date.current.year.pred).each do |start_year|
  cohort = Cohort.find_by!(start_year:)
  CourseCohortProviders::Updater.new(cohort:, course_to_provider_csv: defaults_csv, dry_run: false).call
end

unfunded_csv = "db/seeds/data/unfunded_spring_2026a_course_cohort_providers.csv"
unfunded_cohort = Cohort.find_by!(identifier: "#{Date.current.year}a")
capped_cohort = Cohort.find_by!(identifier: "#{Date.current.year}b")
CourseCohortProviders::Updater.new(cohort: unfunded_cohort, course_to_provider_csv: unfunded_csv, dry_run: false).call
CourseCohortProviders::Updater.new(cohort: capped_cohort, course_to_provider_csv: defaults_csv, dry_run: false).call
