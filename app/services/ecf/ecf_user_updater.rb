module Ecf
  class EcfUserUpdater
    def self.call(user:)
      new(user:).call
    end

    attr_reader :user

    def initialize(user:)
      @user = user
    end

    def call
      return if Rails.application.config.npq_separation[:ecf_api_disabled]

      remote = user.ecf_user

      # JsonApiClient::Resource uses errors for flow control, so failed saves
      # will divert to the rescue block below
      # I'd prefer to use the return value of save, but that's not possible
      remote.email = user.email
      remote.full_name = user.full_name
      remote.get_an_identity_id = user.get_an_identity_id

      return unless remote.changed?

      if remote.save
        EcfSyncRequestLog.create!(
          sync_type: :user_update,
          syncable: user,
          status: :success,
        )
        true
      else
        EcfSyncRequestLog.create!(
          sync_type: :user_update,
          syncable: user,
          status: :failed,
          error_messages: remote.errors.full_messages,
          response_body:,
        )
        false
      end
    rescue StandardError => e
      env = e.try(:env) || {}
      response_body = env["response_body"]
      EcfSyncRequestLog.create!(
        sync_type: :user_update,
        syncable: user,
        status: :failed,
        error_messages: ["#{e.class} - #{e.message}"],
        response_body:,
      )
      return if e.is_a?(JsonApiClient::Errors::ConnectionError)

      Sentry.with_scope do |scope|
        scope.set_context("User", { id: user.id })
        Sentry.capture_exception(e)

        # Re-raise to fail the sync, we'll want to retry again later
        raise e
      end
    end
  end
end
