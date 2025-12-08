(2021..2023).each do |start_year|
  FactoryBot.create(:cohort, :without_funding_cap, start_year:)
end

# Ensure Cohort.next is always created
registration_start_month = Cohort.find_by(start_year: 2021).registration_start_date.month
next_cohort_start_year = Date.current.year + (Date.current.month < registration_start_month ? 0 : 1)

(2024..next_cohort_start_year).each do |start_year|
  FactoryBot.create(:cohort, :with_funding_cap, start_year:)
end

# Add suffixed cohort
FactoryBot.create(:cohort, :with_funding_cap, start_year: 2025,
                                              suffix: "b",
                                              description: "Autumn 2025")
