class Crons::UpdateSchoolsJob < CronJob
  self.cron_expression = "30 4 * * *"

  def perform
    ImportGiasSchoolsJob.perform_later
  end
end
