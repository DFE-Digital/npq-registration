class Admin::BulkOperationsController < AdminController
  def index
    @uploaded_files = current_admin.file_uploads
  end
end
