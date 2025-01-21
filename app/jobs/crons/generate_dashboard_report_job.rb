class Crons::GenerateDashboardReportJob < CronJob
  include Sentry::Cron::MonitorCheckIns

  # Run every hour
  self.cron_expression = "0 * * * *"

  sentry_monitor_check_ins slug: "generate-dashboard"

  def perform
    report = Report.find_or_initialize_by(identifier: "dashboard")
    report.update!(data: ReportService.new.call)
  end
end
