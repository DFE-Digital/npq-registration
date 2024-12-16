module NpqSeparation::Admin::BulkOperations
  class RevertApplicationsToPendingController < NpqSeparation::AdminController
    before_action :set_bulk_operations, :set_bulk_operation, only: %i[index create]

    def create
      if params[:bulk_operations_revert_applications_to_pending] && params[:bulk_operations_revert_applications_to_pending][:file]
        current_admin.bulk_operations.where(type: "BulkOperations::RevertApplicationsToPending").not_ran.destroy_all
        @bulk_operation.file.attach(params[:bulk_operations_revert_applications_to_pending][:file])
        if @bulk_operation.valid?
          @bulk_operation.save!
          @bulk_operation.update!(rows: @bulk_operation.file.download.lines.count)
          redirect_to :npq_separation_admin_bulk_operations_revert_applications_to_pending_index
        else
          render :index, status: :unprocessable_entity
        end
      end
    end

    def run
      bulk_operation = BulkOperation.find(params[:id]) # TODO: check type
      application_ecf_ids = CSV.parse(bulk_operation.file.download, headers: false).flatten
      bulk_operation.update!(ran_at: Time.zone.now)
      # TODO: perform_later using a job
      result = BulkOperation::BulkChangeApplicationsToPending.new(application_ecf_ids:).run!(dry_run: false)
      bulk_operation.update!(result:)
      bulk_operation.update!(finished_at: Time.zone.now)
      redirect_to :npq_separation_admin_bulk_operations_revert_applications_to_pending_index
    end

    def show
      @bulk_operation = BulkOperations::RevertApplicationsToPending.find(params[:id])
    end

  private

    def set_bulk_operations
      @bulk_operations = current_admin.bulk_operations.where(type: "BulkOperations::RevertApplicationsToPending").includes([file_attachment: :blob]).order(:created_at)
    end

    def set_bulk_operation
      @bulk_operation = BulkOperations::RevertApplicationsToPending.new admin: current_admin
    end
  end
end
