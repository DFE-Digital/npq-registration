require "csv"
schools = CSV.table("config/data/202405XX_Schools-disadvantage-lists.csv")
PP50_SCHOOLS_HASH = schools.each_with_object({}) { |school, hash| hash[school[:urn].to_s] = true }
