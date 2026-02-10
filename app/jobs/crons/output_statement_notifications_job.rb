class Crons::OutputStatementNotificationsJob < CronJob
  include Sentry::Cron::MonitorCheckIns

  # run on the 1st of every month at 8:30 AM
  self.cron_expression = "30 8 1 * *"

  sentry_monitor_check_ins slug: "output-statement-notifications"

  def perform
    today = Time.zone.today
    if Statement.with_output_fee.where(deadline_date: today.beginning_of_month..(today + 1.month).end_of_month).any?
      Statements::SendOutputStatementNotifications.new.call
    end
  end
end
