module Applications
  class RevertToPending
    class << self
      def call(application)
        new(application).call
      end
    end

    def initialize(application)
      @application = application
    end

    def call
      @application.update!(lead_provider_approval_status: :pending)
    end
  end
end
