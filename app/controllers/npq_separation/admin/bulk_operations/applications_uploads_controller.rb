module NpqSeparation::Admin::BulkOperations
  class ApplicationsUploadsController < AdminController
    def create
      file_upload = FileUpload.create! admin: current_admin
      file_upload.file.attach(params[:file])
      redirect_to :npq_separation_admin_bulk_operations
    end
  end
end
