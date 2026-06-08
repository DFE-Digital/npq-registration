module TeachingRecordSystem
  module Webhooks
    class PersonDeactivatedProcessor < Base
      WEBHOOK_NAME = "Person deactivated webhook".freeze

      def process!
        if users_matching_merged_with_person.any?
          handle_merged_with_users
        else
          update_deactivated_users_trn!
        end
      end

    private

      def user
        true
      end

      def deactivated_trn
        webhook_message.message["deactivatedPerson"]["trn"]
      end

      def merged_with_trn
        webhook_message.message["mergedWithPerson"]["trn"]
      end

      def users_matching_merged_with_person
        @users_matching_merged_with_person ||= User.with_trn(merged_with_trn)
      end

      def users_matching_deactivated_person
        @users_matching_deactivated_person ||= User.with_trn(deactivated_trn)
      end

      def update_deactivated_users_trn!
        users_matching_deactivated_person.update!(trn: merged_with_trn)
      end

      def handle_merged_with_users
        if user_to_keep.archived? && only_archived_teacher_auth_users_matching_deactivated_person?
          update_deactivated_users_trn!
          merge_and_archive_users(users_to_merge: user_to_keep, merge_into: users_matching_deactivated_person.first)
        elsif user_to_keep.archived? && non_archived_gai_users_matching_deactivated_person?
          merge_extra_deactivated_users
        else
          merge_and_archive_users(users_to_merge: users_matching_deactivated_person, merge_into: user_to_keep)
          merge_extra_merged_with_users
        end
      end

      def only_archived_teacher_auth_users_matching_deactivated_person?
        !all_users_archived?(users_matching_deactivated_person) &&
          all_users_teacher_auth?(users_matching_deactivated_person)
      end

      def non_archived_gai_users_matching_deactivated_person?
        !user_to_keep.teacher_auth_provider? &&
          !all_users_archived?(users_matching_deactivated_person)
      end

      def user_to_keep
        @user_to_keep ||= User
          .with_trn([deactivated_trn, merged_with_trn])
          .order(archived_at: :desc, provider: :desc, updated_at: :desc, id: :desc)
          .where.not(id: users_matching_deactivated_person.ids)
          .first
      end

      def merge_and_archive_users(users_to_merge:, merge_into:)
        Array.wrap(users_to_merge).each do |user_to_merge|
          Users::MergeAndArchive.new(user_to_merge:, user_to_keep: merge_into).call(dry_run: false, allow_archived_users: true)
        end
      end

      def merge_extra_merged_with_users
        extra_merged_with_users = users_matching_merged_with_person.where.not(id: user_to_keep)
        merge_and_archive_users(users_to_merge: extra_merged_with_users, merge_into: user_to_keep)
      end

      def merge_extra_deactivated_users
        most_recent_non_archived_deactivated_user = users_matching_deactivated_person.not_archived.order(updated_at: :desc).first
        other_deactivated_users = users_matching_deactivated_person.where.not(id: most_recent_non_archived_deactivated_user.id)
        merge_and_archive_users(users_to_merge: other_deactivated_users, merge_into: most_recent_non_archived_deactivated_user)
      end

      def correct_format?
        message["deactivatedPerson"].present? &&
          message["deactivatedPerson"]["trn"].present? &&
          message["mergedWithPerson"].present? &&
          message["mergedWithPerson"]["trn"].present?
      end

      def all_users_archived?(users)
        # OPTIMIZE: look at a more effecient way of doing this
        users.all?(&:archived?)
      end

      def all_users_teacher_auth?(users)
        # OPTIMIZE: look at a more effecient way of doing this
        users.all?(&:teacher_auth_provider?)
      end
    end
  end
end
