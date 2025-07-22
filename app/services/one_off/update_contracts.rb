module OneOff
  class UpdateContracts
    def self.call(year:, month:, cohort_year:, csv_path:, dry_run: true)
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

          existing_template = old_template.find_from_existing(per_participant: row["per_participant"])

          if existing_template
            contract.contract_template = existing_template
            Rails.logger.info("[UpdateContract] Found existing template: #{existing_template.id}")
          else
            new_template = old_template.new_from_existing(per_participant: row["per_participant"])
            new_template.save!
            Rails.logger.info("[UpdateContract] New template created: #{new_template.id}")
            contract.contract_template = new_template
          end

          if contract.changed?
            contract.save!
            Rails.logger.info("[UpdateContract] Contract #{contract.id} got template updated: #{old_template.id} to #{contract.contract_template.id}")
          else
            Rails.logger.info("[UpdateContract] Contract #{contract.id} template remains unchanged: #{old_template.id}")
          end
        end

        raise ActiveRecord::Rollback if dry_run
      end
    end
  end
end
