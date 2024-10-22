# frozen_string_literal: true

module Users
  class Archiver
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :user

    def archive!
      raise ArgumentError, "User already archived" if user.archived?

      ApplicationRecord.transaction do
        user.archived_email = user.email
        user.email = "archived-#{user.email}"
        user.save!
      end
    end
  end
end
