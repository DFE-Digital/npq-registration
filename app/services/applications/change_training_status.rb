# frozen_string_literal: true

module Applications
  class ChangeTrainingStatus
    include ActiveModel::Model

    attr_accessor :application
    attr_writer :training_status

    delegate :lead_provider, to: :application

    validates :application, presence: true
    validates :training_status, inclusion: Application.training_statuses.values

    def training_status
      @training_status || application&.training_status
    end

    def change_training_status
      Application.transaction do
        return false if invalid?

        ApplicationState.create!(application:, lead_provider:, state: training_status)
        application.update!(training_status:)

        true
      end
    end
  end
end
