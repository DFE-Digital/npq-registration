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
        message_json.fetch("userId")
      end

      def email
        message_json.fetch("emailAddress")
      end

      def preferred_name
        message_json.fetch("preferredName")
      end

      def full_name
        message_json.values_at("firstName", "middleName", "lastName")
                    .select(&:present?)
                    .join(" ")
      end

      def date_of_birth
        raw_dob = message_json.fetch("dateOfBirth")
        return if raw_dob.blank?

        Date.parse(raw_dob, "%Y-%m-%d")
      end

      def trn
        message_json.fetch("trn")
      end

      def trn_lookup_status
        message_json.fetch("trnLookupStatus")
      end

      def sent_at
        webhook_message.sent_at
      end

    private

      def message_json
        webhook_message.message["user"]
      end
    end
  end
end
