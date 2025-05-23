require "csv"
PP50_SCHOOLS_CSV    = "config/data/January2025/NPQ_Schools_PP50_2025_cohort.csv".freeze
PP50_FE_CSV         = "config/data/January2025/NPQ_FE_PP50_2025_cohort.csv".freeze # FE is further education
EY_CHILDMINDERS_CSV = "config/data/January2025/NPQ_EY_Childminders_2025_cohort.csv".freeze # EY is early years
EY_SCHOOLS_CSV      = "config/data/January2025/NPQ_Disadvantaged_EY_2025_cohort.csv".freeze
EY_LA_NURSERIES_CSV = "config/data/January2025/NPQ_LA_Nursery_Schools_2025_cohort.csv".freeze # LA is local authority

fe = CSV.table(PP50_FE_CSV)
childminders = CSV.table(EY_CHILDMINDERS_CSV)
ey = CSV.table(EY_SCHOOLS_CSV)
la_nurseries = CSV.table(EY_LA_NURSERIES_CSV)
schools = CSV.table(PP50_SCHOOLS_CSV)

pp50_schools = schools.each_with_object({}) { |school, hash| hash[school[:urn].to_s] = true }
ey_ofsted_urn = ey.each_with_object({}) do |school, hash|
  if school[:ofstedurn].present?
    hash[school[:ofstedurn].to_s] = true
  else
    hash[school[:urn].to_s] = true
  end
end

fe_ukprn = fe.each_with_object({}) { |school, hash| hash[school[:ukprn].to_s] = true }
nurseries = la_nurseries.each_with_object({}) { |school, hash| hash[school[:urn].to_s] = true }
childminders_urn = childminders.each_with_object({}) { |school, hash| hash[school[:ofsted_urn].to_s] = true }

LA_DISADVANTAGED_NURSERIES = nurseries
PP50_SCHOOLS_URN_HASH = pp50_schools
PP50_FE_UKPRN_HASH = fe_ukprn
EY_OFSTED_URN_HASH = ey_ofsted_urn
CHILDMINDERS_OFSTED_URN_HASH = childminders_urn
