# frozen_string_literal: true

class BulkOperation::UploadEligibilityListJob < ApplicationJob
  queue_as :default

  def perform(bulk_operation_id:, eligibility_list_type:)
    bulk_operation = BulkOperation::UploadEligibilityList.find(bulk_operation_id)
    Rails.logger.info("Bulk Operation started - bulk_operation_id: #{bulk_operation_id}")
    bulk_operation.run!(eligibility_list_type:)
    Rails.logger.info("Bulk Operation finished - bulk_operation_id: #{bulk_operation_id}")
  end
end
