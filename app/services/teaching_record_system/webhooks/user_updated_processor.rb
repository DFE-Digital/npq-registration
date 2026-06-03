module TeachingRecordSystem
  module Webhooks
    class UserUpdatedProcessor < Base
      WEBHOOK_NAME = "One Login user updated webhook".freeze

      def process!
        user.update!(params_to_update)
      end

    private

      def params_to_update
        { email: user_email }.tap do |params|
          if new_trn.present? && new_trn != user.trn
            params[:trn] = new_trn
            params[:trn_verified] = true
            params[:trn_auto_verified] = true
          end
        end
      end

      def user_uid
        webhook_message.message["oneLoginUser"]["subject"]
      end

      def user_email
        webhook_message.message["oneLoginUser"]["emailAddress"]
      end

      def new_trn
        webhook_message.message["connectedPerson"]["trn"] if webhook_message.message["connectedPerson"]
      end

      def correct_format?
        message["oneLoginUser"].present? &&
          message["oneLoginUser"]["subject"].present?
      end
    end
  end
end
