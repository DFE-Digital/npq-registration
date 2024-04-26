class Admin::ReopeningEmailSubscriptionsController < SuperAdminController
  include Pagy::Backend

  def index
    subscriptions = params[:senco_only] ? [:senco] : %i[senco other_npq]
    @all_users = User.where(email_updates_status: subscriptions)
    @pagy, @users = pagy(@all_users)

    respond_to do |format|
      format.html
      format.csv do
        response.headers["Content-Type"] = "text/csv; charset=utf-8"
        response.headers["Content-Disposition"] = "attachment; filename=reopening_email_subscriptions_#{subscriptions.join("-")}.csv"
      end
    end
  end

  def unsubscribe
    @user = User.find(params[:id])
    if request.post?
      flash[:success] = "Email '#{@user.email}' unsubscribed"
      @user.unsubscribe_from_email_updates

      redirect_to admin_reopening_email_subscriptions_path
    end
  end
end
