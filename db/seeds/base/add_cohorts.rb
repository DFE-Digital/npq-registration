Rails.logger.info("Importing cohorts")

Importers::CreateCohort.new(path_to_csv: Rails.root.join("db/data/cohorts/cohorts.csv")).call

# Ensure Cohort.next is always created
registration_start_month = Cohort.find_by(start_year: 2021).registration_start_date.month
next_cohort_start_year = Date.current.year + (Date.current.month < registration_start_month ? 0 : 1)
FactoryBot.create(:seed_cohort, start_year: next_cohort_start_year) if Cohort.find_by(start_year: next_cohort_start_year).blank?
