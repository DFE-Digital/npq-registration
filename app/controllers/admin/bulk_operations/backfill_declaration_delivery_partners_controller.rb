module Admin::BulkOperations
  class BackfillDeclarationDeliveryPartnersController < Admin::BulkOperations::BaseController
  private

    def bulk_operation_class
      BulkOperation::BackfillDeclarationDeliveryPartners
    end

    def bulk_operation_index
      :admin_bulk_operations_backfill_declaration_delivery_partners
    end
  end
end
