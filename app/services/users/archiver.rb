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
      user.email = "archived-#{user.email}"
      user.uid = nil
      user.provider = nil
      user.save!
    end

    def set_uid_to_nil!
      user.update!(uid: nil)
    end
  end
end
