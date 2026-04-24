# create older cohorts without funding cap
(2021..2023).each do |start_year|
  FactoryBot.create(:cohort, :without_funding_cap, start_year:)
end

# create newer cohorts with funding cap
current_cohort_start_year = Date.current.month < 9 ? (Date.current.year - 1) : Date.current.year
(2024..current_cohort_start_year).each do |start_year|
  FactoryBot.create(:cohort, :with_funding_cap, start_year:)
end

# create next cohorts
FactoryBot.create(:cohort, :next, :unfunded, description: "Unfunded cohort")
FactoryBot.create(:cohort, :next, :with_funding_cap, suffix: "b")
