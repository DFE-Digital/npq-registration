require "csv"
csv = CSV.table("config/data/202407_LA_disadvantaged_nurseries.csv")
nurseries = csv.each_with_object({}) { |school, hash| hash[school[:urn].to_s] = true }

LA_DISADVANTAGED_NURSERIES = nurseries
