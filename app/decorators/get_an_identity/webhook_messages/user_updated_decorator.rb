module GetAnIdentity
  module WebhookMessages
    class UserUpdatedDecorator
      attr_reader :webhook_message

      def initialize(webhook_message)
        @webhook_message = webhook_message
      end

      def correct_formatting?
        message_json.is_a?(Hash) && uid.present?
      end

      def uid
        message_json["uid"]
      end

      def email
        message_json["emailAddress"]
      end

      def full_name
        [
          message_json["firstName"],
          message_json["lastName"],
        ].join(" ")
      end

      def date_of_birth
        raw_dob = message_json["dateOfBirth"]
        return if raw_dob.blank?

        Date.parse(raw_dob, "%Y-%m-%d")
      end

      def trn
        message_json["trn"]
      end

      def trn_lookup_status
        message_json["trnLookupStatus"]
      end

      def trn_verified
        trn_lookup_status == "Found"
      end

      def sent_at
        webhook_message.sent_at
      end

    private

      def message_json
        webhook_message.message
      end
    end
  end
end
