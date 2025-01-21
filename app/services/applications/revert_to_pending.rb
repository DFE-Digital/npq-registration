module Applications
  class RevertToPending
    REVERTABLE_DECLARATION_STATES = %w[voided ineligible awaiting_clawback clawed_back].freeze

    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :change_status_to_pending
    attribute :application
    delegate :lead_provider_approval_status, to: :application

    validates :change_status_to_pending, inclusion: { in: %w[yes no] }
    validates :lead_provider_approval_status, inclusion: { in: %w[accepted rejected] }, if: :application
    validates :application, presence: true
    validate :application_has_no_unremoveable_declarations, if: :application

    def revert
      return true if change_status_to_pending == "no"
      return false if invalid?

      Application.transaction do
        application.application_states.destroy_all
        application.funded_place = nil
        application.pending_lead_provider_approval_status!

        true
      end
    end

  private

    def application_has_no_unremoveable_declarations
      if application.declarations.where.not(state: REVERTABLE_DECLARATION_STATES).any?
        errors.add :base, :pending_unremoveable_declarations
      end
    end
  end
end
