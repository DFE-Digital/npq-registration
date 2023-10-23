class CronTestJop < CronJob
  # set the cron expression to run every 10 minutes
  self.cron_expression = '*/10 * * * *'

  def perform
    Sentry.capture_message("Cron job is working")
  end
end
