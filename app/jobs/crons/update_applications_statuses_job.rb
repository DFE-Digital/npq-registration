class Crons::UpdateApplicationsStatusesJob < CronJob
  include Sentry::Cron::MonitorCheckIns

  # run every two hours
  self.cron_expression = "0 */2 * * *"

  sentry_monitor_check_ins slug: "update-application-statuses"

  def perform
    ApplicationSynchronizationJob.perform_later
  end
end
