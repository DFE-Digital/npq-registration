module Applications
  class Reject
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :application

    validates :application, presence: true
    validate :not_already_rejected
    validate :cannot_change_from_accepted

    def reject
      return false unless valid?

      application.update!(lead_provider_approval_status: "rejected")

      true
    end

  private

    def not_already_rejected
      return unless application
      return unless application.rejected_lead_provider_approval_status?

      errors.add(:application, :has_already_been_rejected)
    end

    def cannot_change_from_accepted
      return unless application
      return unless application.accepted_lead_provider_approval_status?

      errors.add(:application, :cannot_change_from_accepted)
    end
  end
end
