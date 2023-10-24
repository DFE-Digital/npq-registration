class Crons::UpdateApplicationsStatuses < CronJob
  self.cron_expression = "0 */2 * * *"

  def perform
    ApplicationSynchronizationJob.perform_later
  end
end
