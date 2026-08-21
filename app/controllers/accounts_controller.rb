class AccountsController < LoggedInController
  def show
    applications = current_user.applications
    @application_count = applications.count

    if @application_count == 1
      redirect_to accounts_user_registration_path(applications.first)
    else
      @active_applications = applications.active_applications
                                         .includes(:course, :lead_provider)
                                         .order(created_at: :desc, id: :desc)
      @expired_applications = applications.expired_applications
                                          .includes(:course, :lead_provider)
                                          .order(created_at: :desc, id: :desc)
    end
  end
end
