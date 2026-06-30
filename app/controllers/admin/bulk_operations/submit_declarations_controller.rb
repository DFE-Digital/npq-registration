module Admin::BulkOperations
  class SubmitDeclarationsController < BaseController
  private

    def bulk_operation_class
      BulkOperation::SubmitDeclarations
    end

    def bulk_operation_index
      :admin_bulk_operations_submit_declarations
    end
  end
end
