class Crons::MigrationJob < CronJob
  queue_as :high_priority

  include Sentry::Cron::MonitorCheckIns

  # run at 12:30 AM every day
  self.cron_expression = "30 0 * * *"

  sentry_monitor_check_ins slug: "migration"

  def perform
    return unless Rails.application.config.npq_separation[:migration_enabled]

    migrator = Migration::Coordinator.new
    migrator.migrate!
  end
end
