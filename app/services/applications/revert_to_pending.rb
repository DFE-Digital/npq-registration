module Applications
  class RevertToPending
    REMOVEABLE_DECLARATION_STATES = %w[submitted voided ineligible].freeze

    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_reader :application

    attribute :change_status_to_pending
    delegate :lead_provider_approval_status, to: :application

    validates :change_status_to_pending, inclusion: { in: %w[yes] }
    validates :lead_provider_approval_status, inclusion: { in: %w[accepted] }
    validate :application_has_no_unremoveable_declarations

    def initialize(application, ...)
      @application = application
      super(...)
    end

    def revert
      return false unless valid?

      Application.transaction do
        @application.application_states.destroy_all
        @application.declarations.destroy_all
        @application.funded_place = nil
        @application.pending_lead_provider_approval_status!

        true
      end
    end

  private

    def application_has_no_unremoveable_declarations
      if @application.declarations.where.not(state: REMOVEABLE_DECLARATION_STATES).any?
        errors.add :base, :pending_unremoveable_declarations
      end
    end
  end
end
