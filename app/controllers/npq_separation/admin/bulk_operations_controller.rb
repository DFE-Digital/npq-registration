class NpqSeparation::Admin::BulkOperationsController < AdminController
  def index
    @bulk_operations = current_admin.bulk_operations
  end

  def revert_applications_to_pending
    bulk_operation = BulkOperation.find(params[:id])
    application_ecf_ids = CSV.parse(bulk_operation.file.download, headers: false).flatten
    # TODO: perform_later using a job
    result = OneOff::BulkChangeApplicationsToPending.new(application_ecf_ids:).run!(dry_run: false)
    bulk_operation.update!(result:)
    redirect_to npq_separation_admin_bulk_operations_path
  end
end
