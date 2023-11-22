class UploadAnalyticsReportJob < ApplicationJob
  queue_as :default

  def perform
    Exporters::AnalyticsReport.new.call
  end
end
