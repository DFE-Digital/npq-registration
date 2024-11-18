# frozen_string_literal: true

module Applications
  class UpdateTrainingStatus
    include ActiveModel::Model

    attr_reader :application
    attr_writer :training_status

    delegate :lead_provider, to: :application
    validates :training_status, inclusion: Application.training_statuses.values

    def initialize(application, ...)
      @application = application
      super(...)
    end

    def training_status
      @training_status || application.training_status
    end

    def save
      Application.transaction do
        return false if invalid?

        ApplicationState.create!(application:, lead_provider:, state: training_status)
        application.update!(training_status:)

        true
      end
    end
  end
end
