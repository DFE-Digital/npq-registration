class Crons::BatchSendLatestOutcomesJob < CronJob
  include Sentry::Cron::MonitorCheckIns

  DEFAULT_BATCH_SIZE = 200

  # run every 10 minutes
  self.cron_expression = "*/10 * * * *"

  sentry_monitor_check_ins slug: "batch-send-latest-outcomes"

  def perform(batch_size = DEFAULT_BATCH_SIZE)
    outcomes.first(batch_size).each do |outcome|
      SendToQualifiedTeachersAPIJob.perform_now(participant_outcome_id: outcome.id)
    end
  end

  def queue_name
    "participant_outcomes"
  end

private

  def outcomes
    @outcomes ||= ParticipantOutcome.to_send_to_qualified_teachers_api
  end
end
