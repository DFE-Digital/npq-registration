class Crons::SweepStaleSessionsJob < CronJob
  include Sentry::Cron::MonitorCheckIns

  # run at 3:30 AM every day
  self.cron_expression = "30 3 * * *"

  sentry_monitor_check_ins slug: "sweep-stale-sessions"

  def perform
    ActiveRecord::SessionStore::Session
      .where("updated_at < ?", 15.days.ago)
      .delete_all
  end
end
