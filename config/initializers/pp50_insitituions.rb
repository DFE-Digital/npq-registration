require "csv"
schools = CSV.table("config/data/202405XX_Schools-disadvantage-lists.csv")
pp50_schools = schools.each_with_object({}) { |school, hash| hash[school[:urn].to_s] = true }
fe = CSV.table("config/data/pp50further_education.csv")
fe_ukprn = fe.each_with_object({}) { |school, hash| hash[school[:ukprn].to_s] = true }
ey = CSV.table("config/data/early_years.csv")
ey_urn = ey.each_with_object({}) { |school, hash| hash[school[:urn].to_s] = true }
PP50_SCHOOLS_URN_HASH = pp50_schools
PP50_FE_UKPRN_HASH = fe_ukprn
EY_FUNDED_URN_HASH = ey_urn
