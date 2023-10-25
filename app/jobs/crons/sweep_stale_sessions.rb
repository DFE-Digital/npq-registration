class Crons::SweepStaleSessions < CronJob
  self.cron_expression = "30 3 * * *"

  def perform
    SweepStaleSessionsJob.perform_later
  end
end
