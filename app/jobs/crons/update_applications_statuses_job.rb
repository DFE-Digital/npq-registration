class Crons::UpdateApplicationsStatusesJob < CronJob
  # run every two hours
  self.cron_expression = "0 */2 * * *"

  def perform
    ApplicationSynchronizationJob.perform_later
  end
end
