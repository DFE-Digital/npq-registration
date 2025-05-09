require "csv"

namespace :delivery_partners do
  namespace :partners do
    desc "Import delivery partners from csv"
    task :import, %i[import_file dry_run] => :environment do |_t, args|
      raise "Import file not specified" if args[:import_file].blank?
      raise "Import file not present" unless File.exist?(args[:import_file])
      raise "Import file is empty" if File.size(args[:import_file]).zero?

      DeliveryPartner.transaction do
        raise "Delivery Partners already exist" unless DeliveryPartner.count.zero?

        CSV.foreach(args[:import_file], headers: true) do |row|
          DeliveryPartner.create!(ecf_id: row["ECF Id"], name: row["Name"])
        end

        unless args[:dry_run] == "false"
          Rails.logger.info \
            "DRY RUN: Imported #{DeliveryPartner.count} Delivery Partners, now rolling back"

          raise ActiveRecord::Rollback
        end
      end
    end

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
