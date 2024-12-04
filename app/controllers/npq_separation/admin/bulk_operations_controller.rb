class NpqSeparation::Admin::BulkOperationsController < AdminController
  def index
    @bulk_operations = current_admin.bulk_operations
  end
end
