class Crons::EnqueueTokenRefreshesJob < CronJob
  include Sentry::Cron::MonitorCheckIns

  self.cron_expression = "0 * * * *"

  sentry_monitor_check_ins slug: "enqueue-token-refreshes"

  def perform
    User.needing_token_refresh.find_each do |user|
      RefreshUserTokenJob.perform_later(user.id)
    end
  end
end
