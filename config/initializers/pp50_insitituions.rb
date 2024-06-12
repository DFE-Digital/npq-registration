require "csv"
schools = CSV.table("config/data/202405XX_Schools-disadvantage-lists.csv")
pp50_schools = schools.each_with_object({}) { |school, hash| hash[school[:urn].to_s] = true }
fe = CSV.table("config/data/pp50further_education.csv")
fe_ukprn = fe.each_with_object({}) { |school, hash| hash[school[:ukprn].to_s] = true }
ey = CSV.table("config/data/early-years-all-settings.csv")
ey_ofsted_urn = ey.each_with_object({}) { |school, hash| hash[school[:ofsted_urn].to_s] = true }
childminders = CSV.table("config/data/childminders.csv")
childminders_urn = childminders.each_with_object({}) { |school, hash| hash[school[:ofsted_urn].to_s] = true }
PP50_SCHOOLS_URN_HASH = pp50_schools
PP50_FE_UKPRN_HASH = fe_ukprn
EY_OFSTED_URN_HASH = ey_ofsted_urn
CHILDMINDERS_OFSTED_URN_HASH = childminders_urn
