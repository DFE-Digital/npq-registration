class Crons::GenerateDashboardReport < CronJob
  self.cron_expression = "0 * * * *"

  def perform
    DashboardReportJob.perform_later
  end
end
