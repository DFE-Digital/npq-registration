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

# ActiveJob is responsible for scheduling retries rather than Delayed::Job
# See ApplicationJob base file and CronJob
Delayed::Worker.max_attempts = 1
