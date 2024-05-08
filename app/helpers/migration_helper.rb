module MigrationHelper
  def migration_started_at(data_migrations)
    # When a migration is first kicked off all data_migration records are briefly
    # pending (with a `started_at` of `nil`) until a worker picks up the job.
    # We use the current time as the start time in this case.
    data_migrations.map(&:started_at).compact.min || Time.zone.now
  end

  def migration_completed_at(data_migrations)
    data_migrations.map(&:completed_at).compact.max
  end

  def migration_duration_in_words(data_migrations)
    duration_in_seconds = (migration_completed_at(data_migrations) - migration_started_at(data_migrations)).to_i
    ActiveSupport::Duration.build(duration_in_seconds).inspect
  end

  def data_migration_status_tag(data_migration)
    return govuk_tag(text: "Pending", colour: "grey") if data_migration.pending?
    return govuk_tag(text: "In progress - #{data_migration.percentage_migrated}%", colour: "blue") if data_migration.in_progress?

    govuk_tag(text: "Completed", colour: "green")
  end

  def data_migration_failure_count_tag(data_migration)
    return if data_migration.failure_count.zero?

    govuk_tag(text: number_with_delimiter(data_migration.failure_count), colour: "red")
  end

  def data_migration_total_count_tag(data_migration)
    return unless data_migration.total_count&.positive?

    govuk_tag(text: number_with_delimiter(data_migration.total_count), colour: "blue")
  end

  def data_migration_percentage_migrated_successfully_tag(data_migration)
    percentage = data_migration.percentage_migrated_successfully

    colour = if percentage < 80
               "red"
             elsif percentage < 100
               "yellow"
             else
               "green"
             end

    govuk_tag(text: "#{sprintf("%g", percentage)}%", colour:)
  end

  def data_migration_download_failures_report_link(data_migration)
    return unless data_migration.failure_count.positive?

    govuk_link_to("Failures report", download_report_npq_separation_migration_migrations_path(data_migration))
  end
end
