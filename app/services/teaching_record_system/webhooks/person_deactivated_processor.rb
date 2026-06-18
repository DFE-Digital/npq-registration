module TeachingRecordSystem
  module Webhooks
    class PersonDeactivatedProcessor < Base
      WEBHOOK_NAME = "Person deactivated webhook".freeze

      def process!
        return unless merge_into && merged_with_trn

        update_trns!
        merge_and_archive_users(users_to_merge:, merge_into:)
      end

    private

      def user
        true
      end

      def deactivated_trn
        webhook_message.message["deactivatedPerson"]["trn"]
      end

      def merged_with_trn
        webhook_message.message["mergedWithPerson"] && webhook_message.message["mergedWithPerson"]["trn"]
      end

      def users_matching_merged_with_person
        @users_matching_merged_with_person ||= User.with_trn(merged_with_trn)
      end

      def update_trns!
        if users_matching_merged_with_person.any?
          merge_into.update!(trn: merged_with_trn)
        else
          all_matching_users.update!(trn: merged_with_trn)
        end
      end

      def users_to_merge
        all_matching_users.where.not(id: merge_into)
      end

      def merge_into
        matching_users_archived_teacher_auth_users = all_matching_users.archived.with_teacher_auth
        matching_users_gai_non_archived_users = all_matching_users.not_archived.with_get_an_identity_id

        if matching_users_archived_teacher_auth_users.one? && matching_users_gai_non_archived_users.any?
          matching_users_archived_teacher_auth_users.first
        else
          all_matching_users.first
        end
      end

      def all_matching_users
        @all_matching_users ||= User
          .with_trn([deactivated_trn, merged_with_trn])
          .order(archived_at: :desc, provider: :asc, updated_at: :desc, id: :desc)
      end

      def merge_and_archive_users(users_to_merge:, merge_into:)
        Array.wrap(users_to_merge).each do |user_to_merge|
          Users::MergeAndArchive.new(user_to_merge:, user_to_keep: merge_into).call(dry_run: false, allow_archived_users: true)
        end
      end

      def correct_format?
        message["deactivatedPerson"].present? &&
          message["deactivatedPerson"]["trn"].present?
      end
    end
  end
end
