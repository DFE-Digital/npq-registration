class DashboardReportJob < ApplicationJob
  queue_as :default

  def perform
    report = Report.find_or_initialize_by(identifier: "dashboard")
    report.update!(data: Report.new.call)
  end
end
