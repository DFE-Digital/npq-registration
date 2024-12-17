module NpqSeparation::Admin::BulkOperations
  class RejectApplicationsController < NpqSeparation::AdminController
    before_action :set_bulk_operations, :set_bulk_operation, only: %i[index create]
    before_action :find_bulk_operation, only: %i[run show]

    def create
      if params[:bulk_operations_reject_applications] && params[:bulk_operations_reject_applications][:file]
        BulkOperations::RejectApplications.where(type: "BulkOperations::RejectApplications").not_ran.destroy_all
        @bulk_operation.file.attach(params[:bulk_operations_reject_applications][:file])
        if @bulk_operation.valid?
          @bulk_operation.save!
          @bulk_operation.update!(rows: @bulk_operation.file.download.lines.count)
          redirect_to :npq_separation_admin_bulk_operations_reject_applications
        else
          render :index, status: :unprocessable_entity
        end
      end
    end

    def run
      @bulk_operation.update!(ran_at: Time.zone.now, ran_by_admin_id: current_admin.id)
      BulkOperation::BulkRejectApplicationsJob.perform_later(bulk_operation_id: @bulk_operation.id)
      redirect_to :npq_separation_admin_bulk_operations_reject_applications
    end

    def show; end

  private

    def set_bulk_operations
      @bulk_operations = BulkOperations::RejectApplications.all.includes([file_attachment: :blob]).order(:created_at)
    end

    def set_bulk_operation
      @bulk_operation = BulkOperations::RejectApplications.new admin: current_admin
    end

    def find_bulk_operation
      @bulk_operation = BulkOperations::RejectApplications.find(params[:id])
    end
  end
end
