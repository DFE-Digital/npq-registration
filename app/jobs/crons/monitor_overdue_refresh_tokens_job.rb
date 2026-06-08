# Monitors the oauth_tokens table for refresh tokens that should have been refreshed
# by RefreshUserTokenJob (via TeacherAuth::RefreshAccessToken) but have not been.
# If any token is older than the refresh point plus a grace period, the refresh
# pipeline is falling behind and we alert Sentry so it can be investigated before
# tokens expire.
class Crons::MonitorOverdueRefreshTokensJob < CronJob
  include Sentry::Cron::MonitorCheckIns

  # run every hour at 30 minutes past
  self.cron_expression = "30 * * * *"

  sentry_monitor_check_ins slug: "monitor-overdue-refresh-tokens"

  def perform
    overdue_count = OauthToken.overdue_refresh.count
    return if overdue_count.zero?

    Sentry.capture_message(
      "OAuth refresh tokens are not being refreshed",
      level: :error,
      extra: { overdue_count: },
    )
  end
end
