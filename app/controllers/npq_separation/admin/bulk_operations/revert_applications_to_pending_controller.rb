module NpqSeparation::Admin::BulkOperations
  class RevertApplicationsToPendingController < NpqSeparation::Admin::BulkOperations::BaseController
  private

    def bulk_operation_class
      BulkOperation::RevertApplicationsToPending
    end

    def bulk_operation_index
      :npq_separation_admin_bulk_operations_revert_applications_to_pending_index
    end
  end
end
