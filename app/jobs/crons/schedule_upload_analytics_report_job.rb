class Crons::ScheduleUploadAnalyticsReportJob < CronJob
  include Sentry::Cron::MonitorCheckIns
  # 10 minutes after GenerateDashboardReportJob
  self.cron_expression = "10 * * * *"

  sentry_monitor_check_ins slug: "schedule-upload-analytics-report"
  def perform
    UploadAnalyticsReportJob.perform_later
  end
end
