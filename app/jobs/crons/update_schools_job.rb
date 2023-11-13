class Crons::UpdateSchoolsJob < CronJob
  # run at 4:30 AM every day
  self.cron_expression = "30 4 * * *"

  def perform
    ImportGiasSchoolsJob.perform_later
  end
end
