FactoryBot.create(:cohort, start_year: 2021)

# Ensure Cohort.next is always created
registration_start_month = Cohort.find_by(start_year: 2021).registration_start_date.month
next_cohort_start_year = Date.current.year + (Date.current.month < registration_start_month ? 0 : 1)

(2022..next_cohort_start_year).each do |start_year|
  FactoryBot.create(:cohort, start_year:)
end
