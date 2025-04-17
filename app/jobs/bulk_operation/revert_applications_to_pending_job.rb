# frozen_string_literal: true

class BulkOperation::RevertApplicationsToPendingJob < ApplicationJob
  def perform(bulk_operation_id:)
    bulk_operation = BulkOperation::RevertApplicationsToPending.find(bulk_operation_id)
    Rails.logger.info("Bulk Operation started - bulk_operation_id: #{bulk_operation_id}")
    BulkOperation::BulkRevertApplicationsToPending.new(bulk_operation:).run!(dry_run: false)
    Rails.logger.info("Bulk Operation finished - bulk_operation_id: #{bulk_operation_id}")
  end
end
