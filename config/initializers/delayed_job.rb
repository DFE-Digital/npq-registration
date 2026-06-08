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
Delayed::Worker.max_attempts = 18

# Override backoff rate for retries
#
# Offset from first attempt
# 6 seconds
# 0 hours 1 minutes
# 0 hours 13 minutes
# 1 hours 21 minutes
# 5 hours 42 minutes
# 18 hours 40 minutes
# 1 day 7 hours 37 minutes
# 1 day 20 hours 35 minutes
# 2 days 9 hours 33 minutes
# 2 days 22 hours 30 minutes
# 3 days 11 hours 28 minutes
# 4 days 0 hours 26 minutes
# 4 days 13 hours 23 minutes
# 5 days 2 hours 21 minutes
# 5 days 15 hours 19 minutes
# 6 days 4 hours 17 minutes
# 6 days 17 hours 14 minutes
# 7 days 6 hours 12 minutes
ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.class_eval do
  def reschedule_at(db_time_now, attempts, ...)
    db_time_now + ([attempts, 6].min**6) + 5
  end
end
