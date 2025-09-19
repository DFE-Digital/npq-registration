module Applications
  class Reject
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :application
    attribute :reason_for_rejection

    validates :application, presence: true
    validates :reason_for_rejection, presence: true
    validate :not_already_rejected
    validate :no_billable_or_changeable_declarations

    def reject
      return false unless valid?

      application.update!(lead_provider_approval_status: "rejected", reason_for_rejection:)
      application.reload

      true
    end

  private

    def not_already_rejected
      return unless application
      return unless application.rejected_lead_provider_approval_status?

      errors.add(:application, :has_already_been_rejected)
    end

    def no_billable_or_changeable_declarations
      return unless application
      return unless application.declarations.billable_or_changeable.any?

      errors.add(:application, :cannot_reject_with_declarations)
    end
  end
end
