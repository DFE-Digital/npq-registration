module NpqSeparation::Admin::BulkOperations
  class UpdateAndVerifyTrnsController < NpqSeparation::Admin::BulkOperations::BaseController
    before_action :set_bulk_operations, :set_bulk_operation, only: %i[index create]

  private

    def set_bulk_operations
      @bulk_operations = BulkOperation::UpdateAndVerifyTrns.all.includes([file_attachment: :blob]).order(created_at: :desc, id: :desc)
    end

    def set_bulk_operation
      @bulk_operation = BulkOperation::UpdateAndVerifyTrns.new admin: current_admin
    end

    def bulk_operation_class
      BulkOperation::UpdateAndVerifyTrns
    end

    def bulk_operation_job_class
      BulkOperation::BulkUpdateAndVerifyTrnsJob
    end

    def bulk_operation_param_key
      :bulk_operation_update_and_verify_trns
    end

    def bulk_operation_index
      :npq_separation_admin_bulk_operations_update_and_verify_trns
    end
  end
end
