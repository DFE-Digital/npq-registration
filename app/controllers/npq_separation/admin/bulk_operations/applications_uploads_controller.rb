module NpqSeparation::Admin::BulkOperations
  class ApplicationsUploadsController < AdminController
    def create
      current_admin.bulk_operations.where(type: "BulkOperations::RevertApplicationsToPending").not_ran.destroy_all
      bulk_operation = BulkOperations::RevertApplicationsToPending.create! admin: current_admin
      bulk_operation.file.attach(params[:file])
      bulk_operation.update!(rows: bulk_operation.file.download.lines.count)
      redirect_to :npq_separation_admin_bulk_operations
    end
  end
end
