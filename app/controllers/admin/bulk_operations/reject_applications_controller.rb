module Admin::BulkOperations
  class RejectApplicationsController < Admin::BulkOperations::BaseController
  private

    def bulk_operation_class
      BulkOperation::RejectApplications
    end

    def bulk_operation_index
      :admin_bulk_operations_reject_applications
    end
  end
end
