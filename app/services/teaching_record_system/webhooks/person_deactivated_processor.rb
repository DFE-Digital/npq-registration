module TeachingRecordSystem
  module Webhooks
    class PersonDeactivatedProcessor < Base
      WEBHOOK_NAME = "Person deactivated webhook".freeze

      def process!
        return unless merge_into && merged_with_trn

        all_matching_users_query.update!(trn: merged_with_trn)
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

      def users_to_merge
        all_matching_users[1..]
      end

      def merge_into
        all_matching_users[0]
      end

      def all_matching_users
        @all_matching_users ||= all_matching_users_query.to_a
      end

      def all_matching_users_query
        @all_matching_users_query ||= User
          .with_trn([deactivated_trn, merged_with_trn])
          .order(provider: :asc, archived_at: :desc, updated_at: :desc, id: :desc)
      end

      def merge_and_archive_users(users_to_merge:, merge_into:)
        users_to_merge.each do |user_to_merge|
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
