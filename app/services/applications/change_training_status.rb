# frozen_string_literal: true

module Applications
  class ChangeTrainingStatus
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    REASON_OPTIONS = {
      "deferred" => Participants::Defer::DEFERRAL_REASONS,
      "withdrawn" => Participants::Withdraw::WITHDRAWAL_REASONS,
    }.freeze

    attribute :application
    attribute :reason
    attribute :training_status

    delegate :lead_provider, to: :application

    validates :application, presence: true
    validates :training_status, inclusion: Application.training_statuses.values
    validates :reason, inclusion: { in: :valid_reasons }, if: :reason_required?
    validate :do_not_defer_if_without_declarations, if: :application
    validate :do_not_change_status_of_pending_application, if: :application

    before_validation(unless: :reason_required?) { self.reason = nil }

    def change_training_status
      Application.transaction do
        return false if invalid?
        return true if status_unchanged?

        service = build_delegated_service

        if service.call
          application.reload
          true
        else
          service.errors.messages.values.flatten.each { |m| errors.add(:base, m) }
          false
        end
      end
    end

    def training_status_options
      Application.training_statuses.values.without(application&.training_status)
    end

    def reason_options
      REASON_OPTIONS
    end

  private

    def build_delegated_service
      service_attrs = {
        lead_provider: application.lead_provider,
        participant_id: application.user.ecf_id,
        course_identifier: application.course.identifier,
      }

      service_attrs[:reason] = reason if reason_required?

      case training_status
      when "deferred"
        Participants::Defer.new(service_attrs)
      when "active"
        Participants::Resume.new(service_attrs)
      when "withdrawn"
        Participants::Withdraw.new(service_attrs)
      end
    end

    def reason_required?
      training_status.present? && training_status != "active"
    end

    def valid_reasons
      reason_options[training_status] || []
    end

    def status_unchanged?
      training_status == application&.training_status
    end

    def do_not_defer_if_without_declarations
      return unless training_status == "deferred"
      return unless application.accepted_lead_provider_approval_status?

      if application.declarations.empty?
        errors.add(:training_status, :invalid_deferral_no_declarations)
      end
    end

    def do_not_change_status_of_pending_application
      return if errors.any?

      if application.lead_provider_approval_status == "pending"
        errors.add(:training_status, :pending_lead_provider_approval_status)
      end
    end
  end
end
