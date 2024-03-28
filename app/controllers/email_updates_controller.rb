class EmailUpdatesController < ApplicationController
  before_action do
    redirect_to root_path unless current_user.persisted?
  end
  def new
    session["request_email_updates"] = nil

    @form = EmailUpdates.new
  end

  # Save form
  def create
    @form = EmailUpdates.new(email_update_params)
    if @form.valid?
      current_user.update_email_updates_status(@form)
      EmailUpdatesConfirmationMailer.email_updates_confirmation_mail(to: current_user.email, service_link: "https://#{ENV['DOMAIN']}", unsubscribe_link:).deliver_now
    else
      render :new
    end
  end

  # Reguires `email_updates_unsubscribe_key` as param
  def unsubscribe
    user = User.find_by(email_updates_unsubscribe_key: params[:unsubscribe_key])

    if user
      user.unsubscribe_from_email_updates
    else
      flash[:error] = "Invalid unsubscribe link"
      redirect_to root_path
    end
  end

private

  def email_update_params
    params[:email_updates] ? params.require(:email_updates).permit(:email_updates_status) : {}
  end

  def unsubscribe_link
    "https://#{ENV['DOMAIN']}#{unsubscribe_email_updates_path(unsubscribe_key: current_user.email_updates_unsubscribe_key)}"
  end
end
