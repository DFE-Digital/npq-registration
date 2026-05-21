module TeachingRecordSystem
  module Webhooks
    class TrnRequestCompletedProcessor
      def self.call(webhook_message:)
        new(webhook_message:).call
      end

      def initialize(webhook_message:)
        self.webhook_message = webhook_message
      end

      def call
        return incorrect_format_failure unless correct_format?
        return no_user_found_failure unless user

        user.update!(trn: new_trn, trn_verified: true, trn_auto_verified: true)
        webhook_message.make_processed!
      end

    private

      attr_accessor :webhook_message

      delegate :message, to: :webhook_message

      def user_uid
        webhook_message.message["trnRequest"]["oneLoginUserSubject"]
      end

      def user
        @user ||= User.find_by(uid: user_uid)
      end

      def new_trn
        webhook_message.message["trnRequest"]["trn"]
      end

      def incorrect_format_failure
        record_error("Invalid message format")
      end

      def no_user_found_failure
        record_error("No user found with uid: #{user_uid}")
      end

      def correct_format?
        message["trnRequest"].present? &&
          message["trnRequest"]["trn"].present? &&
          message["trnRequest"]["oneLoginUserSubject"].present?
      end

      def record_error(message)
        webhook_message.update!(
          status: :failed,
          status_comment: message,
          processed_at: Time.zone.now,
        )
        Sentry.capture_message("[TRS webhook] #{message}")
      end
    end
  end
end
