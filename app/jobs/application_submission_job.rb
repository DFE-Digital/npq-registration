class ApplicationSubmissionJob < ApplicationJob
  queue_as :default

  def perform(user:)
    if user.synced_to_ecf?
      update_ecf_user_details(user:)
    else
      create_link_to_ecf_user(user:)
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

  def create_link_to_ecf_user(user:)
    ecf_user = find_ecf_user_by_email(user:)

    if ecf_user
      user.update!(ecf_id: ecf_user.id)
      # Now make sure the user we found is fully up to date
      update_ecf_user_details(user:)
    else
      Services::Ecf::EcfUserCreator.new(user:).call
    end
  end

  def update_ecf_user_details(user:)
    # rubocop:disable Rails/SaveBang
    # This is not necessary
    user.ecf_user.update(
      email: user.email,
      full_name: user.full_name,
      get_an_identity_id: user.get_an_identity_id,
    )
    # rubocop:enable Rails/SaveBang

    # Record that the GAI ID has been synced
    user.update_column(:get_an_identity_id_synced_to_ecf, true) if user.get_an_identity_id.present?
  rescue StandardError => e
    Sentry.with_scope do |scope|
      scope.set_context("User", { id: user.id, ecf_id: user.ecf_id })
      Sentry.capture_exception(e)

      # We aren't re-raising the error here, updating the user failing
      # should not halt application submission
    end
  end

  def find_ecf_user_by_email(user:)
    Services::Ecf::EcfUserFinder.new(user:).call
  rescue StandardError => e
    env = e.try(:env) || {}
    response_body = env["response_body"]
    EcfSyncRequestLog.create!(
      sync_type: :user_lookup,
      syncable: user,
      status: :failed,
      error_messages: ["#{e.class} - #{e.message}"],
      response_body:,
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
