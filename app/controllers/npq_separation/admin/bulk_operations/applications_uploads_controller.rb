module NpqSeparation::Admin::BulkOperations
  class ApplicationsUploadsController < AdminController
    def create
      current_admin.file_uploads.destroy_all # TODO: do this only after new file loaded
      file_upload = FileUpload.create! admin: current_admin
      file_upload.file.attach(params[:file])
      file_upload.update!(rows: file_upload.file.download.lines.count)
      redirect_to :npq_separation_admin_bulk_operations
    end
  end
end
