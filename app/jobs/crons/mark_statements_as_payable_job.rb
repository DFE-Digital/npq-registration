class Crons::MarkStatementsAsPayableJob < CronJob
  include Sentry::Cron::MonitorCheckIns

  # run at 12AM every day
  self.cron_expression = "0 0 * * *"

  sentry_monitor_check_ins slug: "mark-statements-as-payable"

  def perform
    Statement.where(state: "open", deadline_date: 1.day.ago.to_date).find_each do |statement|
      ::Statements::MarkAsPayable.new(statement:).mark
    end
  end
end
