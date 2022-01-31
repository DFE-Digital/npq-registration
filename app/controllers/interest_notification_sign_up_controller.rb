class InterestNotificationSignUpController < ApplicationController
  before_action :set_notification_form, only: %i[new]

  def new; end

  def create
    @notification_form = Forms::RegistrationInterestNotification.new(notification_params)
    @notification_form.notification_option = "yes"

    if @notification_form.valid?
      @notification_form.save!
      redirect_to registration_interest_sign_up_confirm_path(email: @notification_form.email)
    else
      render :new
    end
  end

  def confirm
    @email = params[:email]
  end

private

  def notification_params
    params.require(:forms_registration_interest_notification).permit(:email)
  end

  def set_notification_form
    @notification_form = Forms::RegistrationInterestNotification.new
  end
end
