class Crons::BatchSendLatestOutcomesJob < CronJob
  include Sentry::Cron::MonitorCheckIns

  DEFAULT_BATCH_SIZE = 200

  # run every 10 minutes
  self.cron_expression = "*/10 * * * *"

  sentry_monitor_check_ins slug: "batch-send-latest-outcomes"

  discard_on StandardError do |_job, exception|
    Sentry.capture_exception(exception)
  end

  def perform(batch_size = DEFAULT_BATCH_SIZE)
    outcomes.first(batch_size).each { |outcome| SendToQualifiedTeachersAPIJob.perform_later(participant_outcome_id: outcome.id) }
  end

  def queue_name
    "participant_outcomes"
  end

private

  def outcomes
    @outcomes ||= ParticipantOutcome.to_send_to_qualified_teachers_api
  end
end
