module Applications
  class Reject
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :application

    validates :application, presence: { message: I18n.t("application.missing_application") }
    validate :not_already_rejected
    validate :cannot_change_from_accepted

    def call
      return self unless valid?

      application.update!(lead_provider_approval_status: "rejected")
      application
    end

  private

    def not_already_rejected
      return unless application
      return unless application.rejected?

      errors.add(:application, I18n.t("application.has_already_been_rejected"))
    end

    def cannot_change_from_accepted
      return unless application
      return unless application.accepted?

      errors.add(:application, I18n.t("application.cannot_change_from_accepted"))
    end
  end
end
