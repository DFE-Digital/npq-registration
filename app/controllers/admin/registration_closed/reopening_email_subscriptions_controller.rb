class Admin::RegistrationClosed::ReopeningEmailSubscriptionsController < AdminController
  before_action :require_super_admin

  def index
    npqs = params[:senco_only] ? :npq_senco : :all
    @all_registration_interests = RegistrationInterest.send(npqs).order(:created_at)
    @pagy, @registration_interests = pagy(@all_registration_interests)

    respond_to do |format|
      format.html
      format.csv do
        response.headers["Content-Type"] = "text/csv; charset=utf-8"
        response.headers["Content-Disposition"] = "attachment; filename=reopening_email_subscriptions_#{npqs}.csv"
      end
    end
  end

  def unsubscribe
    @registration_interest = RegistrationInterest.find(params[:id])
    if request.post?
      flash[:success] = "Email '#{@registration_interest.email}' unsubscribed"
      @registration_interest.destroy!

      redirect_to admin_registration_closed_reopening_email_subscriptions_path
    end
  end
end
