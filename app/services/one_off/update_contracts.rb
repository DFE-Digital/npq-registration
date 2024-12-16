module OneOff
  class UpdateContracts
    def self.call(year:, month:, cohort_year:, csv_path:)
      csv_file = CSV.read(csv_path, headers: true)

      ActiveRecord::Base.transaction do
        csv_file.each do |row|
          lead_provider = LeadProvider.find_by!(name: row["provider_name"])
          cohort = Cohort.find_by!(start_year: cohort_year)
          course = Course.find_by!(identifier: row["course_identifier"])

          statements = Statement.where(year:, month:, cohort: cohort, lead_provider: lead_provider)
          raise "There should be only one statement present (#{row.to_h})" if statements.count != 1

          contracts = statements.first.contracts.where(course: course)
          raise "There should be only one contract present (#{row.to_h})" if contracts.count != 1

          contract = contracts.first
          old_template = contract.contract_template
          new_template = old_template.new_from_existing(per_participant: row["per_participant"])
          new_template.save!

          contract.contract_template = new_template
          contract.save!
          Rails.logger.info("[UpdateContract] Contract #{contract.id} got template updated: #{old_template.id} to #{new_template.id}")
        end
      end
    end
  end
end
