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
    else
      render :new
    end
  end

  # Reguires `email_updates_unsubscribe_key` as param
  def unsubscribe; end

private

  def email_update_params
    params[:email_updates] ? params.require(:email_updates).permit(:email_updates_status) : {}
  end
end
