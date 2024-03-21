class Crons::UpdateTsfPrimaryAttributesJob < CronJob
  include Sentry::Cron::MonitorCheckIns

  self.cron_expression = "0 */2 * * *"

  sentry_monitor_check_ins slug: "update-tsf-primary-attribute-statuses"

  def perform
    TsfPrimaryAttributsSynchronizationJob.perform_later
  end
end
