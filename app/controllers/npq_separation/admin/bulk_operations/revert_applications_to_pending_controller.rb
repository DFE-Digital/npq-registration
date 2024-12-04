module NpqSeparation::Admin::BulkOperations
  class RevertApplicationsToPendingController < NpqSeparation::AdminController
    def show
      @bulk_operations = current_admin.bulk_operations.where(type: "BulkOperations::RevertApplicationsToPending").includes([file_attachment: :blob])
    end
  end
end
