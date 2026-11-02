class Crons::FailingJob < CronJob
  # include Sentry::Cron::MonitorCheckIns

  self.cron_expression = "* * * * *"

  # sentry_monitor_check_ins slug: "monitor-overdue-refresh-tokens"

  def perform
    raise "Cron Testing Failed"
  end
end
