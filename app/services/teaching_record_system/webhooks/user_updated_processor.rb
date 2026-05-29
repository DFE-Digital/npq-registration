module TeachingRecordSystem
  module Webhooks
    class UserUpdatedProcessor
      include BaseProcessorMethods

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

      def webhook_name
        "User updated webhook"
      end

      def user_uid
        webhook_message.message["oneLoginUser"]["subject"]
      end

      def new_trn
        webhook_message.message["connectedPerson"]["trn"]
      end

      def correct_format?
        message["oneLoginUser"].present? &&
          message["oneLoginUser"]["subject"].present? &&
          message["connectedPerson"].present? &&
          message["connectedPerson"]["trn"].present?
      end
    end
  end
end
