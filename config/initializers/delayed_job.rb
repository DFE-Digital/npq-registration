# FYI currently we are specifying the queue list in terraform.
# If you add a new queue, you'll need to update the file:
# `terraform/application/application.tf` - line 72

Delayed::Worker.queue_attributes = {
  high_priority: { priority: -10 },
  default: { priority: 0 },
  participant_outcomes: { priority: 5 },
  low_priority: { priority: 10 },
  migration: { priority: 0 },
  dfe_analytics: { priority: 0 },
}
