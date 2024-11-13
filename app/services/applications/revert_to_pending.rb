module Applications
  class RevertToPending
    BLOCKING_DECLARATION_STATES = %w[submitted voided ineligible].freeze

    class << self
      def call(application)
        new(application).call
      end
    end

    def initialize(application)
      @application = application
    end

    def call
      Application.transaction do
        return true if @application.pending_lead_provider_approval_status?

        if application_has_declarations?
          raise RevertToPendingError, "Cannot revert to pending, Application has Declarations"
        end

        @application.declarations.destroy_all
        @application.funded_place = nil
        @application.pending_lead_provider_approval_status!

        true
      end
    end

    class RevertToPendingError < StandardError; end

  private

    def application_has_declarations?
      @application.declarations.where(state: BLOCKING_DECLARATION_STATES).any?
    end
  end
end
