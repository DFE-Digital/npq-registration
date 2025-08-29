module GetAnIdentityService
  module Webhooks
    class UserUpdatedProcessor
      class << self
        def call(webhook_message:)
          new(webhook_message:).call
        end
      end

      attr_reader :webhook_message

      def initialize(webhook_message:)
        @webhook_message = webhook_message
      end

      def call
        return wrong_processor_failure unless webhook_message.message_type == "UserUpdated"
        return incorrect_format_failure unless decorated_message.correct_formatting?
        return no_user_found_failure if user.blank?

        if user.updated_from_tra_at.present? && user.updated_from_tra_at > webhook_message.sent_at
          return more_recent_data_recorded_success
        end

        if update_user
          webhook_message.make_processed!
        else
          record_error(user.errors.full_messages.join(", "))
        end
      rescue StandardError => e
        record_error([e.class, e.message].join(": "))
      end

    private

      delegate :trn, :trn_lookup_status, to: :decorated_message
      delegate :decorated_message, to: :webhook_message

      def record_error(message, send_to_sentry: true)
        webhook_message.update!(
          status: :failed,
          status_comment: message,
          processed_at: Time.zone.now,
        )
        Sentry.capture_message("[GAI webhook] #{message}") if send_to_sentry
        false
      end

      def wrong_processor_failure
        record_error("Wrong processor used for message type: #{webhook_message.message_type}")
      end

      def no_user_found_failure
        record_error("No user found with get_an_identity_id: #{decorated_message.uid}", send_to_sentry: false)
      end

      def incorrect_format_failure
        record_error("Invalid message format")
      end

      def more_recent_data_recorded_success
        webhook_message.update!(
          status: :processed,
          status_comment: "More recent data recorded",
          processed_at: Time.zone.now,
        )
        true
      end

      def user
        @user ||= User.find_by_get_an_identity_id(decorated_message.uid)
      end

      def update_user
        user.assign_attributes({
          full_name: decorated_message.full_name,
          date_of_birth: decorated_message.date_of_birth,
          email: decorated_message.email,
          updated_from_tra_at: decorated_message.sent_at,
        })
        user.set_trn_from_provider_data(trn:, trn_lookup_status:)
        user.save # rubocop:disable Rails/SaveBang - return value is used by caller
      end
    end
  end
end
