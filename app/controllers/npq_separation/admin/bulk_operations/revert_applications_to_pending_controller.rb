module NpqSeparation::Admin::BulkOperations
  class RevertApplicationsToPendingController < NpqSeparation::AdminController
    def index
      @bulk_operations = current_admin.bulk_operations.where(type: "BulkOperations::RevertApplicationsToPending").includes([file_attachment: :blob])
    end

    def create
      # TODO: file validation
      if params[:file]
        current_admin.bulk_operations.where(type: "BulkOperations::RevertApplicationsToPending").not_ran.destroy_all
        bulk_operation = BulkOperations::RevertApplicationsToPending.create! admin: current_admin
        bulk_operation.file.attach(params[:file])
        bulk_operation.update!(rows: bulk_operation.file.download.lines.count)
      end
      redirect_to :npq_separation_admin_bulk_operations_revert_applications_to_pending_index
    end

    def run
      bulk_operation = BulkOperation.find(params[:id]) # TODO: check type
      application_ecf_ids = CSV.parse(bulk_operation.file.download, headers: false).flatten
      # TODO: perform_later using a job
      result = BulkOperation::BulkChangeApplicationsToPending.new(application_ecf_ids:).run!(dry_run: false)
      bulk_operation.update!(result:)
      redirect_to :npq_separation_admin_bulk_operations_revert_applications_to_pending_index
    end
  end
end
