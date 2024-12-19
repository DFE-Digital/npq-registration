module NpqSeparation::Admin::BulkOperations
  class RejectApplicationsController < NpqSeparation::AdminController
    before_action :set_bulk_operations, :set_bulk_operation, only: %i[index create]
    before_action :find_bulk_operation, only: %i[run show]

    def create
      if (file = params.dig(:bulk_operation_reject_applications, :file))
        BulkOperation::RejectApplications.not_ran.destroy_all
        @bulk_operation.file.attach(file)
        if @bulk_operation.valid?
          @bulk_operation.save!
          @bulk_operation.update!(row_count: @bulk_operation.file.download.lines.count)
          return redirect_to :npq_separation_admin_bulk_operations_reject_applications
        end
      end

      render :index, status: :unprocessable_entity
    end

    def run
      @bulk_operation.update!(started_at: Time.zone.now, ran_by_admin_id: current_admin.id)
      BulkOperation::BulkRejectApplicationsJob.perform_later(bulk_operation_id: @bulk_operation.id)
      redirect_to :npq_separation_admin_bulk_operations_reject_applications
    end

    def show
      # empty method, because rubocop will complain in the before_action otherwise
    end

  private

    def set_bulk_operations
      @bulk_operations = BulkOperation::RejectApplications.all.includes([file_attachment: :blob]).order(:created_at)
    end

    def set_bulk_operation
      @bulk_operation = BulkOperation::RejectApplications.new admin: current_admin
    end

    def find_bulk_operation
      @bulk_operation = BulkOperation::RejectApplications.find(params[:id])
    end
  end
end
