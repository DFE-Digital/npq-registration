module TeachingRecordSystem
  module Webhooks
    class TrnRequestCompletedProcessor < Base
      WEBHOOK_NAME = "TRN request completed webhook".freeze

      def process!
        User.transaction do
          user.update!(trn: new_trn, trn_verified: true, trn_auto_verified: true)
          merge_and_archive_other_users_with_same_trn
          user.refresh_token&.destroy!
        end

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

      def merge_and_archive_other_users_with_same_trn
        User.not_archived.with_trn(new_trn).where.not(id: user.id).find_each do |other_user|
          Users::MergeAndArchive.new(user_to_merge: other_user, user_to_keep: user).call(dry_run: false)
        end
      end

      def correct_format?
        message["trnRequest"].present? &&
          message["trnRequest"]["trn"].present?
      end
    end
  end
end
