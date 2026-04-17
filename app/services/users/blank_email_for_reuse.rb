# frozen_string_literal: true

module Users
  class BlankEmailForReuse
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :user

    def call
      ApplicationRecord.transaction do
        user.update!(
          archived_email: user.email,
          archived_at: Time.zone.now,
          email: nil,
          uid: nil,
          provider: nil,
        )
      end

      Sentry.capture_message(
        "Blanked email on the user due to reuse when used by a later participant",
        level: :info,
        extra: { ecf_id: user.ecf_id },
      )
    end
  end
end
