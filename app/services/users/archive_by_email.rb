# frozen_string_literal: true

module Users
  class ArchiveByEmail
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :user
    private :user

    def call
      if user_with_matching_email
        ApplicationRecord.transaction do
          move_applications(from_user: user_with_matching_email, to_user: user)
          move_participant_id_changes(from_user: user_with_matching_email, to_user: user)
          user.participant_id_changes.find_or_create_by!(from_participant_id: user_with_matching_email.ecf_id, to_participant_id: user.ecf_id)
        end
        Rails.logger.info("Archiving user with clashing email address ID=#{user_with_matching_email.id}")
        Users::Archiver.new(user: user_with_matching_email.reload).archive!
      end
    end

  private

    def user_with_matching_email
      return unless user.email

      @user_with_matching_email ||= Users::Query.new(user:).user_with_matching_email
    end

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
