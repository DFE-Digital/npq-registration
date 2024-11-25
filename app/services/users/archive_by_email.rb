# frozen_string_literal: true

module Users
  class ArchiveByEmail
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :user

    def call
      ApplicationRecord.transaction do
        users_with_matching_email.each do |user_with_matching_email|
          move_applications(from_user: user_with_matching_email, to_user: user)
          if Feature.ecf_api_disabled?
            move_participant_id_changes(from_user: user_with_matching_email, to_user: user)
            user.participant_id_changes.find_or_create_by!(from_participant_id: user_with_matching_email.ecf_id, to_participant_id: user.ecf_id)
          end
        end
      end
      users_with_matching_email.each do |user_with_matching_email|
        Rails.logger.info("Archiving user with clashing email address ID=#{user_with_matching_email.id}")
        Users::Archiver.new(user: user_with_matching_email).archive!
      end
    end

  private

    def users_with_matching_email
      return [] unless user.email

      @users_with_matching_email = User.where(email: user.email).where.not(id: user.id).all
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
