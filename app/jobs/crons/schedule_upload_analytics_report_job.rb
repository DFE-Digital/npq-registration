class Crons::ScheduleUploadAnalyticsReportJob < CronJob
  # 10 minutes after GenerateDashboardReportJob
  self.cron_expression = "10 * * * *"

  def perform
    UploadAnalyticsReportJob.perform_later
  end
end
