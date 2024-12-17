# frozen_string_literal: true

class BulkOperation::BulkRejectApplicationsJob < ApplicationJob
  def perform(bulk_operation_id:)
    bulk_operation = BulkOperations::RejectApplications.find(bulk_operation_id)
    application_ecf_ids = CSV.parse(bulk_operation.file.download, headers: false).flatten
    Rails.logger.info("Bulk Operation started - bulk_operation_id: #{bulk_operation_id}")
    result = BulkOperation::BulkRejectApplications.new(application_ecf_ids:).run!
    bulk_operation.update!(result:, finished_at: Time.zone.now)
    Rails.logger.info("Bulk Operation finished - bulk_operation_id: #{bulk_operation_id}")
  end
end
