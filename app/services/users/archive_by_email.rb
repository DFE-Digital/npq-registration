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
          user.participant_id_changes.create!(from_participant_id: user_with_matching_email.ecf_id, to_participant_id: user.ecf_id) if Feature.ecf_api_disabled?
        end
      end
      users_with_matching_email.each do |user_with_matching_email|
        Users::Archiver.new(user: user_with_matching_email).archive!
      end
    end

  private

    def users_with_matching_email
      @users_with_matching_email = User.where(email: user.email).all
    end

    def move_applications(from_user:, to_user:)
      from_user.applications.each do |application|
        application.update!(user: to_user)
      end
    end
  end
end
