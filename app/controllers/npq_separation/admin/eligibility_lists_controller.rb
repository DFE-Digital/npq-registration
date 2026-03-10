class NpqSeparation::Admin::EligibilityListsController < NpqSeparation::AdminController
  before_action :require_super_admin

  def show
    @bulk_operation = BulkOperation::UploadEligibilityList.where(finished_at: nil).order(created_at: :desc).first || BulkOperation::UploadEligibilityList.new(admin: current_admin)
  end

  def create
    @bulk_operation = BulkOperation::UploadEligibilityList.new(admin: current_admin, eligibility_list_type: params.dig(:bulk_operation_upload_eligibility_list, :eligibility_list_type))
    if (file = params.dig(:bulk_operation_upload_eligibility_list, :file))
      @bulk_operation.file.attach(file)
      if @bulk_operation.save
        @bulk_operation.update!(started_at: Time.zone.now, ran_by_admin_id: current_admin.id)
        BulkOperation::UploadEligibilityListJob.perform_later(bulk_operation_id: @bulk_operation.id, eligibility_list_type: params.dig(:bulk_operation_upload_eligibility_list, :eligibility_list_type))
        flash[:success] = "The file #{@bulk_operation.file.filename} is being processed."
        return redirect_to npq_separation_admin_eligibility_lists_path
      end
    else
      @bulk_operation.errors.add(:file, :blank)
    end

    render :show, status: :unprocessable_entity
  end
end
