# frozen_string_literal: true

module Users
  class Archiver
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :user

    def archive!
      raise ArgumentError, "User already archived" if user.archived?

      user.archived_email = user.email
      user.archived_at = Time.zone.now
      user.email = email_for_archived_user(user.email)
      user.uid = nil
      user.provider = nil
      user.save!
    end

    def set_uid_to_nil!
      user.update!(uid: nil)
    end

  private

    def email_for_archived_user(original_email)
      if User.find_by(email: "archived-#{original_email}")
        "archived-2-#{original_email}"
      else
        "archived-#{original_email}"
      end
    end
  end
end
