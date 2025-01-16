# frozen_string_literal: true

module Users
  class ArchiveByEmail
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :user
    private :user

    def call
      if user_with_matching_email
        MergeAndArchive.new(user_ecf_id_to_merge: user_with_matching_email.ecf_id, user_ecf_id_to_keep: user.ecf_id).call(dry_run: false)
      end
    end

  private

    def user_with_matching_email
      return unless user.email

      @user_with_matching_email ||= Users::Query.new(user:).user_with_matching_email
    end
  end
end
