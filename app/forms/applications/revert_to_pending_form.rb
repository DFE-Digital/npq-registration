module Applications
  class RevertToPendingForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_reader :application

    attribute :change_status_to_pending
    delegate :lead_provider_approval_status, to: :application

    validates :change_status_to_pending, inclusion: { in: %w[yes] }
    validates :lead_provider_approval_status, inclusion: { in: %w[accepted] }

    def initialize(application, ...)
      @application = application
      super(...)
    end

    def save
      return false unless valid?

      RevertToPending.new(application).call
    end
  end
end
