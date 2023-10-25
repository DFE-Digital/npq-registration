class Crons::UpdateSchoolsJob < CronJob
  self.cron_expression = "*/10 * * * *"

  def perform
    ImportGiasSchoolsJob.perform_later
  end
end
