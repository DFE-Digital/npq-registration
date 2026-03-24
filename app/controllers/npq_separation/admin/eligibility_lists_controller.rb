class NpqSeparation::Admin::EligibilityListsController < NpqSeparation::AdminController
  before_action :require_super_admin
  before_action :set_bulk_operations
  before_action :set_bulk_operation, only: %i[create]
  before_action :attach_file, only: %i[create]

  def create
    if @bulk_operation.save
      @bulk_operation.update!(started_at: Time.zone.now, ran_by_admin_id: current_admin.id)
      BulkOperation::UploadEligibilityListJob.perform_later(bulk_operation_id: @bulk_operation.id)
      flash[:success] = "The file #{@bulk_operation.file.filename} is being processed."
      return redirect_to npq_separation_admin_eligibility_lists_path
    end

    render :show, status: :unprocessable_content
  end

private

  def set_bulk_operations
    bulk_operation_classes = BulkOperation::UploadEligibilityList.subclasses
    @bulk_operations = bulk_operation_classes.index_with do |bulk_operation_class|
      bulk_operation_class.where(finished_at: nil).order(created_at: :desc).first || bulk_operation_class.new(admin: current_admin)
    end
    @last_bulk_operations = bulk_operation_classes.index_with do |bulk_operation_class|
      bulk_operation_class.order(created_at: :desc).first
    end
  end

  def set_bulk_operation
    @param_key = params.keys.select { |key| key.starts_with?("bulk_operation_upload_eligibility_list_") }.first
    eligibility_list_type = params.dig(@param_key, :eligibility_list_type)
    bulk_operation_class = eligibility_list_type.constantize::BULK_OPERATION_CLASS
    @bulk_operation = @bulk_operations[bulk_operation_class]
  end

  def attach_file
    file = params.dig(@param_key, :file)
    @bulk_operation.file.attach(file) if file
  end
end
