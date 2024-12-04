module NpqSeparation::Admin::BulkOperations
  class ApplicationsUploadsController < NpqSeparation::AdminController
    def create
      # TODO: file validation
      if params[:file]
        current_admin.bulk_operations.where(type: "BulkOperations::RevertApplicationsToPending").not_ran.destroy_all
        bulk_operation = BulkOperations::RevertApplicationsToPending.create! admin: current_admin
        bulk_operation.file.attach(params[:file])
        bulk_operation.update!(rows: bulk_operation.file.download.lines.count)
      end
      redirect_to :npq_separation_admin_bulk_operations_revert_applications_to_pending
    end
  end
end
