class AdminService::ApplicationSubmissionsController < AdminController
  def create
    user = User.find(params[:user_id])

    if user.synced_to_ecf? && user.applications_synced_to_ecf?
      flash[:error] = "User has already been synced to ECF"
    else
      existing_ecf_sync_jobs = user.ecf_sync_jobs.to_a

      if ApplicationSubmissionJob.perform_later(user:, email_template: nil)
        existing_ecf_sync_jobs.each(&:delete)
        flash[:success] = "Sync to ECF scheduled"
      else
        flash[:error] = "Failed to enqueue sync job, try again in a few moments"
      end
    end

    redirect_to admin_user_path(user)
  end
end
