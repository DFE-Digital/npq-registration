# Used to be called by a cron job (Crons::ScheduleUploadAnalyticsReportJob) sheduled to run "10 * * * *"
# but that cron job was deleted as part of CPDNPQ-2721, because it's likely this analytics report is not needed anymore.
class UploadAnalyticsReportJob < ApplicationJob
  queue_as :default

  def perform
    Exporters::AnalyticsReport.new.call
  end
end
