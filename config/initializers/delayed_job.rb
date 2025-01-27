# FYI currently we are specifying the queue list in terraform.
# If you add a new queue, you'll need to update the file:
# `terraform/application/application.tf` - line 72

Delayed::Worker.queue_attributes = {
  high_priority: { priority: -10 },
  default: { priority: 0 },
  participant_outcomes: { priority: 5 },
  low_priority: { priority: 10 },
  dfe_analytics: { priority: 0 },
}

# Non of our jobs should take longer than this and if they are they should be
# broken up into multiple jobs
Delayed::Worker.max_run_time = 30.minutes

# The default of 25 is too high, instead we should retry less times and with
# lower frequency
Delayed::Worker.max_attempts = 8

# Override backoff rate for retries
ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.class_eval do
  def reschedule_at(db_time_now, attempts, ...)
    db_time_now + (attempts**6) + 5
  end
end
