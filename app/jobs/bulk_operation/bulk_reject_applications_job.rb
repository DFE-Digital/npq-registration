# frozen_string_literal: true

class BulkOperation::BulkRejectApplicationsJob < ApplicationJob
  def perform(bulk_operation_id:)
    bulk_operation = BulkOperation::RejectApplications.find(bulk_operation_id)
    application_ecf_ids = CSV.parse(bulk_operation.file.download, headers: false).flatten
    Rails.logger.info("Bulk Operation started - bulk_operation_id: #{bulk_operation_id}")
    BulkOperation::BulkRejectApplications.new(application_ecf_ids:, bulk_operation:).run!
    Rails.logger.info("Bulk Operation finished - bulk_operation_id: #{bulk_operation_id}")
  end
end
