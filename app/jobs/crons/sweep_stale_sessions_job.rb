class Crons::SweepStaleSessionsJob < CronJob
  # run at 3:30 AM every day
  self.cron_expression = "30 3 * * *"

  def perform
    SweepStaleSessionsJob.perform_later
  end
end
