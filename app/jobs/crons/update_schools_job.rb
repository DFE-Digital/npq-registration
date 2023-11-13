class Crons::UpdateSchoolsJob < CronJob
  include Sentry::Cron::MonitorCheckIns

  # run at 4:30 AM every day
  self.cron_expression = "30 4 * * *"

  sentry_monitor_check_ins slug: "update-schools"

  def perform
    ImportGiasSchoolsJob.perform_later
  end
end
