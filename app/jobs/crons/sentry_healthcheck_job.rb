# A cron job that is monitored by Sentry to check that sentry is reporting errors correctly
class Crons::SentryHealthcheckJob < CronJob
  include Sentry::Cron::MonitorCheckIns

  # run every hour
  self.cron_expression = "0 * * * *"

  sentry_monitor_check_ins slug: "sentry-healthcheck"

  def perform
    true
  end
end
