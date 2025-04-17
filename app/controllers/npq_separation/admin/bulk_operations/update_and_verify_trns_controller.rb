module NpqSeparation::Admin::BulkOperations
  class UpdateAndVerifyTrnsController < NpqSeparation::Admin::BulkOperations::BaseController
  private

    def sort_order
      { created_at: :desc, id: :desc }
    end

    def bulk_operation_class
      BulkOperation::UpdateAndVerifyTrns
    end

    def bulk_operation_index
      :npq_separation_admin_bulk_operations_update_and_verify_trns
    end
  end
end
