# frozen_string_literal: true

module Users
  class Archiver
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :user

    def archive!(blank_email: false)
      raise ArgumentError, "User already archived" if user.archived?

      user.archived_email = user.email
      user.archived_at = Time.zone.now
      user.email = blank_email ? nil : email_for_archived_user(user.email)
      user.uid = nil
      user.provider = nil
      user.save!

      send_sentry_capture_message if blank_email
    end

    def set_uid_to_nil!
      user.update!(uid: nil)
    end

  private

    def send_sentry_capture_message
      Sentry.capture_message(
        "Blanked email on the user due to reuse when used by a later participant",
        level: :info,
        extra: { ecf_id: user.ecf_id },
      )
    end

    def email_for_archived_user(original_email)
      if User.find_by(email: "archived-#{original_email}")
        "archived-2-#{original_email}"
      else
        "archived-#{original_email}"
      end
    end
  end
end
