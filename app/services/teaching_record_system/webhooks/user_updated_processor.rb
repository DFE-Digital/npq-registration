module TeachingRecordSystem
  module Webhooks
    class UserUpdatedProcessor < Base
      WEBHOOK_NAME = "One Login user updated webhook".freeze

      def process!
        User.transaction do
          user.update!(params_to_update)
          if new_trn.present?
            merge_and_archive_other_users_with_same_trn
            user.refresh_token&.destroy!
          end
        end
      end

    private

      def params_to_update
        { email: user_email }.tap do |params|
          if new_trn.present?
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

      def merge_and_archive_other_users_with_same_trn
        users_with_same_trn = User.not_archived.with_trn(new_trn).order(created_at: :desc).to_a
        user_to_keep = users_with_same_trn[0]

        users_with_same_trn[1..].each do |user_to_merge|
          Users::MergeAndArchive.new(user_to_merge:, user_to_keep:).call(dry_run: false)
        end
      end

      def correct_format?
        message["oneLoginUser"].present?
      end
    end
  end
end
