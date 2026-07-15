module Admin::BulkOperations
  class UpdateAndVerifyTrnsController < Admin::BulkOperations::BaseController
  private

    def bulk_operation_class
      BulkOperation::UpdateAndVerifyTrns
    end

    def bulk_operation_index
      :admin_bulk_operations_update_and_verify_trns
    end
  end
end
