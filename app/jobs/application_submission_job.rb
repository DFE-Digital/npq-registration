class ApplicationSubmissionJob < ApplicationJob
  queue_as :default

  def perform(user:)
    unless user.synced_to_ecf?
      ecf_user = ecf_user_for(user:)

      if ecf_user
        user.update!(ecf_id: ecf_user.id)
      else
        Services::Ecf::EcfUserCreator.new(user:).call
      end
    end

    user.applications.includes(:lead_provider, :course).where(ecf_id: nil).each do |application|
      Services::Ecf::NpqProfileCreator.new(application:).call

      ApplicationSubmissionMailer.application_submitted_mail(
        to: user.email,
        full_name: user.full_name,
        provider_name: application.lead_provider.name,
        course_name: application.course.name,
      ).deliver_now
    end
  end

  private

  def ecf_user_for(user:)
    Services::Ecf::EcfUserFinder.new(user:).call
  rescue StandardError => e
    EcfSyncRequestLog.create(
      sync_type: :user_lookup,
      syncable: user,
      status: :failed,
      error_messages: ["#{e.class} - #{e.message}"],
      response_body: e.env["response_body"],
    )
    Sentry.with_scope do |scope|
      scope.set_context("User", { id: user.id })
      Sentry.capture_exception(e)

      # Re-raise to fail the job, we don't want to continue if we couldn't confirm the existence
      # or non-existence of an ECF user, a failure indicates some sort of communication issue and we should
      # retry the job later.
      raise e
    end
  end
end
