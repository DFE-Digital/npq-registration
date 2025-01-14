# frozen_string_literal: true

class BulkOperation::BulkChangeApplicationsToPendingJob < ApplicationJob
  def perform(bulk_operation_id:)
    bulk_operation = BulkOperation::RevertApplicationsToPending.find(bulk_operation_id)
    application_ecf_ids = CSV.parse(bulk_operation.file.download, headers: false).flatten
    Rails.logger.info("Bulk Operation started - bulk_operation_id: #{bulk_operation_id}")
    BulkOperation::BulkChangeApplicationsToPending.new(application_ecf_ids:, bulk_operation:).run!(dry_run: false)
    Rails.logger.info("Bulk Operation finished - bulk_operation_id: #{bulk_operation_id}")
  end
end
