require "csv"

namespace :delivery_partners do
  namespace :partners do
    desc "Export all delivery partners to a csv"
    task :export, %i[export_file] => :environment do |_t, args|
      raise "Export file not specified" if args[:export_file].blank?

      CSV.open(args[:export_file], "w") do |csv|
        csv << ["ECF Id", "Name"]

        DeliveryPartner.order(id: :asc).find_each do |delivery_partner|
          csv << [delivery_partner.ecf_id, delivery_partner.name]
        end
      end
    end
  end

  namespace :partnerships do
    desc "Export all delivery partnerships to a csv"
    task :export, %i[export_file] => :environment do |_t, args|
      raise "Export file not specified" if args[:export_file].blank?

      CSV.open(args[:export_file], "w") do |csv|
        csv << ["Lead Provider ECF Id", "Cohort Start Year", "Delivery Partner ECF Id"]

        DeliveryPartnership
            .order(id: :asc)
            .includes(:lead_provider, :cohort, :delivery_partner)
            .find_each(batch_size: 500) do |partnership|
          csv << [
            partnership.lead_provider.ecf_id,
            partnership.cohort.start_year,
            partnership.delivery_partner.ecf_id,
          ]
        end
      end
    end
  end
end
