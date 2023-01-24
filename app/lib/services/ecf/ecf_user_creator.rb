module Services
  module Ecf
    class EcfUserCreator
      attr_reader :user

      def initialize(user:)
        @user = user
      end

      def call
        remote = EcfApi::User.new(email: user.email, full_name: user.full_name)

        # JsonApiClient::Resource uses errors for flow control, so failed saves
        # will divert to the rescue block below
        # I'd prefer to use the return value of save, but that's not possible
        remote.save
        user.update!(ecf_id: remote.id)

        EcfSyncRequestLog.create(
          sync_type: :user_creation,
          syncable: user,
          status: :success,
        )
      rescue StandardError => e
        env = e.try(:env) || {}
        response_body = env["response_body"]
        EcfSyncRequestLog.create(
          sync_type: :user_creation,
          syncable: user,
          status: :failed,
          error_messages: ["#{e.class} - #{e.message}"],
          response_body:,
        )
        Sentry.with_scope do |scope|
          scope.set_context("User", { id: user.id })
          Sentry.capture_exception(e)

          # Re-raise to fail the sync, we'll want to retry again later
          raise e
        end
      end
    end
  end
end
