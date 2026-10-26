class EmailUpdatesController < PublicPagesController
  skip_before_action :verify_authenticity_token, only: :unsubscribe

  def new
    session["request_email_updates"] = nil

    @form = EmailUpdates.new(email: current_user&.email)
  end

  # Save form
  def create
    @form = EmailUpdates.new(email_update_params)

    if @form.valid?
      registration_interest = RegistrationInterest.find_or_initialize_by(email: @form.email)
      registration_interest.update!(course: @form.course)
      EmailUpdatesConfirmationMailer.email_updates_confirmation_mail(to: @form.email, service_link: service_url, unsubscribe_link: unsubscribe_link(registration_interest)).deliver_now
    else
      render :new, status: :unprocessable_content
    end
  end

  # Requires `unsubscribe_key` as param, from a registration interest (or a user who signed up before)
  def unsubscribe
    if request.post?
      registration_interest = RegistrationInterest.find_by(unsubscribe_key: params[:unsubscribe_key]) if params[:unsubscribe_key].present?
      user = User.find_by(email_updates_unsubscribe_key: params[:unsubscribe_key]) if params[:unsubscribe_key].present?

      if registration_interest
        registration_interest.destroy!
        redirect_to unsubscribed_email_updates_path
      elsif user
        user.unsubscribe_from_email_updates
        redirect_to unsubscribed_email_updates_path
      else
        flash[:error] = "Invalid unsubscribe link"
        redirect_to root_path
      end
    end
  end

  def unsubscribed; end

private

  def email_update_params
    params.require(:email_updates).permit(:email, :course)
  end

  def unsubscribe_link(registration_interest)
    "#{service_url}#{unsubscribe_email_updates_path(unsubscribe_key: registration_interest.unsubscribe_key)}"
  end

  def service_url
    if Rails.env.production?
      "https://register-national-professional-qualifications.education.gov.uk/"
    else
      "https://#{ENV['DOMAIN']}"
    end
  end
end
