# Background job responsible for checking Sentry configuration
# for our Jobs.
#
# Will be safely deleted once its purpose is completed.
class Crons::SentryCheckerJob < CronJob
  self.cron_expression = "0 */1 * * *"

  def perform
    Raven.capture_message("Sentry checker job is running")
  end
end
