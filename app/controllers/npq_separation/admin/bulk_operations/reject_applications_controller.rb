module NpqSeparation::Admin::BulkOperations
  class RejectApplicationsController < NpqSeparation::Admin::BulkOperations::BaseController
  private

    def bulk_operation_class
      BulkOperation::RejectApplications
    end

    def bulk_operation_index
      :npq_separation_admin_bulk_operations_reject_applications
    end
  end
end
