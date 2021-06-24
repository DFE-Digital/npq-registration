class ApplicationSubmissionJob < ApplicationJob
  queue_as :default

  def perform(user:)
    if user.ecf_id.blank?
      ecf_user = Services::EcfUserFinder.new(user: user).call

      if ecf_user
        user.update!(ecf_id: ecf_user.id)
      else
        Services::EcfUserCreator.new(user: user).call
      end
    end

    user.applications.where(ecf_id: nil).each do |application|
      Services::NpqProfileCreator.new(application: application).call

      ApplicationSubmissionMailer.application_submitted_mail(
        to: user.email,
        full_name: user.full_name,
        provider_name: application.lead_provider.name,
      ).deliver_now
    end
  end
end
