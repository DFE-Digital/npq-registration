module TeachingRecordSystem
  module Webhooks
    class TrnRequestCompletedProcessor < Base
      WEBHOOK_NAME = "TRN request completed webhook".freeze

      def process!
        user.update!(trn: new_trn, trn_verified: true, trn_auto_verified: true)

        if user.trn_previously_changed?(from: nil) && user.email.present?
          TrnAllocatedMailer.trn_allocated_mail(to: user.email, full_name: user.full_name, trn: new_trn).deliver_later
        end
      end

    private

      def user_uid
        webhook_message.message["trnRequest"]["oneLoginUserSubject"]
      end

      def new_trn
        webhook_message.message["trnRequest"]["trn"]
      end

      def correct_format?
        message["trnRequest"].present? &&
          message["trnRequest"]["trn"].present?
      end
    end
  end
end
