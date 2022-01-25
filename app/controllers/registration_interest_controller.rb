class RegistrationInterestController < ApplicationController
  def new
    @notification_form = Forms::RegistrationInterestNotification.new
  end

  def create
    @notification_form = Forms::RegistrationInterestNotification.new(notification_params)

    if @notification_form.selected_no?
      redirect_to registration_interest_no_notification_path and return
    end

    if @notification_form.valid?
      ActiveRecord::Base.transaction do
        RegistrationInterest.create!(
          email: @notification_form.email,
          term: @notification_form.current_term,
        )
      rescue ActiveRecord::RecordInvalid
        render :new
      end
      redirect_to registration_interest_confirm_path(email: @notification_form.email)
    else
      render :new
    end
  end

  def confirm
    @email = params[:email]
  end

  def no_notification; end

private

  def notification_params
    params.require(:forms_registration_interest_notification).permit(:notification_option, :email)
  end
end
