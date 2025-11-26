module OneOff
  class MoveApplicationsToAutumn2025
    BATCH_SIZE = 100
    AUTUMN_START_POINT = Time.zone.parse("2025-08-01 00:00:00").freeze

    def initialize(lead_provider:, changelog:)
      @lead_provider = lead_provider
      @changelog = changelog
    end

    def move!(dry_run: true)
      dry_run = (dry_run != false)

      Application.transaction do
        if paid_or_payable_declarations.any?
          raise "Applications already have declarations on paid or payable statements"
        end

        if schedules_missing_from_autumn_cohort.any?
          raise "Missing schedules in new cohort: #{schedules_missing_from_autumn_cohort.inspect}"
        end

        if next_output_fee_statement.nil?
          raise "No output fee statement in 2025-2 cohort"
        end

        log "DRY RUN: Will rollback afterwards" if dry_run

        move_applications_in_batches!

        if dry_run
          log "DRY RUN: Rolling back"
          raise ActiveRecord::Rollback
        end
      end
    end

  private

    attr_reader :lead_provider

    def record_change(object)
      @changelog.write("#{object.class},#{object.id},#{object&.ecf_id}\n")
    end

    def log(msg)
      Rails.logger.info(msg)
    end

    def spring_cohort
      @spring_cohort ||= Cohort.find_by!(identifier: "2025-1")
    end

    def autumn_cohort
      @autumn_cohort ||= Cohort.find_by!(identifier: "2025-2")
    end

    def applications_to_move
      Application.where(lead_provider:,
                        cohort: spring_cohort,
                        created_at: AUTUMN_START_POINT..)
    end

    def source_schedules
      @source_schedules ||=
        Schedule.distinct
                .joins(:applications)
                .merge(applications_to_move)
                .pluck(:course_group_id, :identifier)
    end

    def target_schedules
      @target_schedules ||=
        Schedule.where(cohort: autumn_cohort)
                .index_by { |s| [s.course_group_id, s.identifier] }
    end

    def schedules_missing_from_autumn_cohort
      @schedules_missing_from_autumn_cohort ||=
        (source_schedules - target_schedules.keys)
    end

    def fetch_autumn_schedule(schedule)
      schedule_key = [schedule.course_group_id, schedule.identifier]

      target_schedules.fetch(schedule_key)
    end

    def paid_or_payable_declarations
      Declaration.joins(:application, :statements)
                 .merge(applications_to_move)
                 .where.not(statements: { state: :open })
    end

    def next_output_fee_statement
      @next_output_fee_statement ||= lead_provider.next_output_fee_statement(autumn_cohort)
    end

    def move_applications_in_batches!
      # fetch static list of application ids move since we are updating whether
      # those applications match the scope as we process them
      application_ids = applications_to_move.pluck(:id)
      total = application_ids.length
      count_so_far = 0

      application_ids.each_slice(BATCH_SIZE) do |application_ids_batch|
        count_so_far += application_ids_batch.length
        log "Updating Cohort for #{count_so_far} / #{total} Applications"

        move_application_batch(application_ids_batch)
      end
    end

    def move_application_batch(ids)
      Application.includes(:schedule, :cohort,
                           declarations: { statement_items: :statement,
                                           cohort: [] })
                 .find(ids)
                 .each do |application|
        move_application_to_autumn(application)
      end
    end

    def move_application_to_autumn(application)
      application.cohort = autumn_cohort

      if application.schedule.present?
        application.schedule = fetch_autumn_schedule(application.schedule)
      end

      # Save without changing the applications updated_at timestamp so that this
      # is invisible to the API but do use correct time for PaperTrail created at
      application.skip_touch_user_if_changed = true
      application.paper_trail_options[:synchronize_version_creation_timestamp] = false
      application.save!(touch: false)
      record_change(application)

      application.declarations.each do |declaration|
        next unless declaration.cohort == spring_cohort

        move_declaration_to_autumn(declaration)
      end
    end

    def move_declaration_to_autumn(declaration)
      declaration.cohort = autumn_cohort
      declaration.paper_trail_options[:synchronize_version_creation_timestamp] = false
      declaration.save!(touch: false)
      record_change(declaration)

      declaration.statement_items.each do |statement_item|
        unless statement_item.statement.open?
          # this line should never be encountered because of the earlier check
          # but check and bail out here if the declaration is unmoveable
          raise "Declaration against paid or payable statement"
        end

        statement_item.statement = next_output_fee_statement
        statement_item.save!
        record_change(statement_item)
      end
    end
  end
end
