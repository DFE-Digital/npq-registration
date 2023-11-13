class Crons::GenerateDashboardReportJob < CronJob
  # Run every hour
  self.cron_expression = "0 * * * *"

  def perform
    DashboardReportJob.perform_later
  end
end
