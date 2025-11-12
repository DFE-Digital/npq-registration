namespace :one_off do
  desc "Move autumn applications from Spring 2025 Cohort to Autumn 2025"
  task :move_applications_to_autumn_2025, %i[lead_provider_id dry_run] => :environment do |_task, args|
    Rails.logger = Logger.new($stdout) unless Rails.env.test?
    dry_run = args[:dry_run] != "false"

    spring_cohort = Cohort.find_by!(identifier: "2025-1")
    autumn_cohort = Cohort.find_by!(identifier: "2025-2")
    lead_provider = LeadProvider.find(args[:lead_provider_id])
    schedule_map  = Schedule.where(cohort: autumn_cohort)
                            .index_by { |s| [s.course_group_id, s.identifier] }
    batch_size    = 100

    application_scope =
      Application.where(lead_provider:,
                        cohort: spring_cohort,
                        created_at: Time.zone.parse("2025-08-01 00:00:00")..)

    Application.transaction do
      if Declaration.joins(:application, :statements)
                    .merge(application_scope)
                    .where.not(statements: { state: :open })
                    .any?
        raise "Applications already have declarations on paid or payable statements"
      end

      selected_schedules = Schedule.distinct
                                  .joins(:applications)
                                  .merge(application_scope)
                                  .pluck(:course_group_id, :identifier)

      missing_schedules = (selected_schedules - schedule_map.keys)
      if missing_schedules.any?
        raise "Missing schedules in new cohort: #{missing_schedules.inspect}"
      end

      next_output_fee_statement = lead_provider.next_output_fee_statement(autumn_cohort)
      if next_output_fee_statement.nil?
        raise "No output fee statement in 2025-2 cohort"
      end

      Rails.logger.info "DRY RUN: Will rollback afterwards" if dry_run

      # select static list of application ids since the loop will change those
      # which matching the scope
      application_ids = application_scope.pluck(:id)
      total = application_ids.length
      count_so_far = 0

      logfile = if Rails.env.test?
                  Tempfile.new.open
                else
                  Rails.root.join("tmp/migrated_applications.csv").open("w")
                end

      application_ids.each_slice(batch_size) do |application_ids_batch|
        count_so_far += application_ids_batch.length
        Rails.logger.info "Updating Cohort for #{count_so_far} / #{total} Applications"

        Application.includes(:schedule, :declarations)
                   .find(application_ids_batch)
                   .each do |application|
          application.cohort = autumn_cohort

          if application.schedule.present?
            schedule_key = [application.schedule.course_group_id,
                            application.schedule.identifier]

            application.schedule = schedule_map.fetch(schedule_key)
          end

          # Save without changing the applications updated_at timestamp
          # but do use correct time for PaperTrail created at
          application.paper_trail_options[:synchronize_version_creation_timestamp] = false
          application.save!(touch: false)

          logfile.write("Application,#{application.id}\n")

          application.declarations.each do |declaration|
            declaration.cohort = autumn_cohort
            declaration.save!
            logfile.write("Declaration,#{declaration.id}\n")

            declaration.statement_items.each do |statement_item|
              unless statement_item.statement.open?
                raise "Declaration against paid or payable statement"
              end

              statement_item.statement = next_output_fee_statement
              statement_item.save!
              logfile.write("StatementItem,#{statement_item.id}\n")
            end
          end
        end
      end
      logfile.close

      if dry_run
        Rails.logger.info "DRY RUN: Rolling back"
        raise ActiveRecord::Rollback
      end
    end
  end
end
