module TeachingRecordSystem
  module Webhooks
    class TrnRequestCompletedProcessor
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
        "TRN request completed webhook"
      end

      def user_uid
        webhook_message.message["trnRequest"]["oneLoginUserSubject"]
      end

      def new_trn
        webhook_message.message["trnRequest"]["trn"]
      end

      def correct_format?
        message["trnRequest"].present? &&
          message["trnRequest"]["trn"].present? &&
          message["trnRequest"]["oneLoginUserSubject"].present?
      end
    end
  end
end
