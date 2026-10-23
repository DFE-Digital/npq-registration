class EmailUpdatesController < PublicPagesController
  def new
    session["request_email_updates"] = nil

    @form = EmailUpdates.new(email: current_user&.email)
  end

  # Save form
  def create
    @form = EmailUpdates.new(email_update_params)

    if @form.valid?
      registration_interest = RegistrationInterest.find_or_create_by!(email: @form.email) do |registration_interest|
        registration_interest.course = @form.course # only used on create
      end
      registration_interest.course = @form.course # used for update
      registration_interest.save!
      EmailUpdatesConfirmationMailer.email_updates_confirmation_mail(to: @form.email, service_link: service_url, unsubscribe_link:).deliver_now
    else
      render :new, status: :unprocessable_content
    end
  end

  # Reguires `email_updates_unsubscribe_key` as param
  def unsubscribe
    if request.post?
      user = User.find_by(email_updates_unsubscribe_key: params[:unsubscribe_key])

      if user
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

  def unsubscribe_link
    # "#{service_url}#{unsubscribe_email_updates_path(unsubscribe_key: current_user.email_updates_unsubscribe_key)}"
    # TODO: make the unsubscribe link work for non-logged in users.
    ""
  end

  def service_url
    if Rails.env.production?
      "https://register-national-professional-qualifications.education.gov.uk/"
    else
      "https://#{ENV['DOMAIN']}"
    end
  end
end
