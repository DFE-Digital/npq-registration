class Crons::UpdateSchoolsJob < CronJob
  include Sentry::Cron::MonitorCheckIns

  # run every day at 4:30 AM
  self.cron_expression = "30 4 * * *"

  sentry_monitor_check_ins slug: "update-schools"

  def perform
    ImportGiasSchools.new.call
  end
end
