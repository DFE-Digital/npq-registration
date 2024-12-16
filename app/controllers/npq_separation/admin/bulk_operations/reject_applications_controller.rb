module NpqSeparation::Admin::BulkOperations
  class RejectApplicationsController < NpqSeparation::AdminController
    before_action :set_bulk_operations, :set_bulk_operation, only: %i[index create]

    def create
      if params[:bulk_operations_reject_applications] && params[:bulk_operations_reject_applications][:file]
        current_admin.bulk_operations.where(type: "BulkOperations::RejectApplications").not_ran.destroy_all
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
      bulk_operation = BulkOperation.find(params[:id]) # TODO: check type
      application_ecf_ids = CSV.parse(bulk_operation.file.download, headers: false).flatten
      bulk_operation.update!(ran_at: Time.zone.now)
      # TODO: perform_later using a job
      result = BulkOperation::BulkRejectApplications.new(application_ecf_ids:).run!
      bulk_operation.update!(result:)
      bulk_operation.update!(finished_at: Time.zone.now)
      redirect_to :npq_separation_admin_bulk_operations_reject_applications
    end

    def show
      @bulk_operation = BulkOperations::RejectApplications.find(params[:id])
    end

  private

    def set_bulk_operations
      @bulk_operations = current_admin.bulk_operations.where(type: "BulkOperations::RejectApplications").includes([file_attachment: :blob]).order(:created_at)
    end

    def set_bulk_operation
      @bulk_operation = BulkOperations::RejectApplications.new admin: current_admin
    end
  end
end
