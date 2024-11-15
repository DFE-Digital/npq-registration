class Crons::CheckAnalyticsEntity < CronJob
  include Sentry::Cron::MonitorCheckIns

  self.cron_expression = "0 2 * * *"

  sentry_monitor_check_ins slug: "check-analytics-entity"

  def perform
    DfE::Analytics::EntityTableCheckJob.perform_later
  end

  def queue_name
    "dfe_analytics"
  end
end
