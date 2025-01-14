# frozen_string_literal: true

module Users
  class MergeAndArchive
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :user_to_merge
    attribute :user_to_keep
    attribute :set_uid, :boolean, default: false
    private :user_to_merge, :user_to_keep, :set_uid

    def call(dry_run: true)
      ApplicationRecord.transaction do
        move_applications(from_user: user_to_merge, to_user: user_to_keep)
        move_participant_id_changes(from_user: user_to_merge, to_user: user_to_keep)
        user_to_keep.participant_id_changes.find_or_create_by!(from_participant_id: user_to_merge.ecf_id, to_participant_id: user_to_keep.ecf_id)
        uid_to_keep = user_to_merge.uid if user_to_merge.uid.present? && user_to_keep.uid.blank?

        Rails.logger.info("Archiving user ID=#{user_to_merge.id}")
        Users::Archiver.new(user: user_to_merge.reload).archive!

        user_to_keep.update!(uid: uid_to_keep) if uid_to_keep && set_uid

        raise ActiveRecord::Rollback if dry_run
      end
    end

  private

    def move_applications(from_user:, to_user:)
      from_user.applications.each do |application|
        application.update!(user: to_user)
      end
    end

    def move_participant_id_changes(from_user:, to_user:)
      from_user.participant_id_changes.update!(user: to_user)
    end
  end
end
