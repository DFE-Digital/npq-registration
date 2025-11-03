# frozen_string_literal: true

class BulkOperation::BackfillDeclarationDeliveryPartnersJob < ApplicationJob
  def perform(bulk_operation_id:)
    bulk_operation = BulkOperation::BackfillDeclarationDeliveryPartners.find(bulk_operation_id)
    Rails.logger.info("Bulk Operation started - bulk_operation_id: #{bulk_operation_id}")
    bulk_operation.run!
    Rails.logger.info("Bulk Operation finished - bulk_operation_id: #{bulk_operation_id}")
  end
end
