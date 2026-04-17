# frozen_string_literal: true

module Participants
  class Defer < Action
    DEFERRAL_REASONS = %w[
      bereavement
      long-term-sickness
      parental-leave
      career-break
      other
    ].freeze

    attribute :reason

    validates :reason, inclusion: { in: DEFERRAL_REASONS }, allow_blank: false
    validate :not_already_deferred
    validate :not_withdrawn
    validate :has_declarations

    def defer
      return false if invalid?

      ActiveRecord::Base.transaction do
        create_application_state!(state: :deferred, reason:)
        application.deferred_training_status!
        participant.reload
        send_email
      end

      true
    end
    alias_method :call, :defer

  private

    def not_withdrawn
      errors.add(:participant_id, :already_withdrawn) if application&.withdrawn_training_status?
    end

    def not_already_deferred
      errors.add(:participant_id, :already_deferred) if application&.deferred_training_status?
    end

    def has_declarations
      errors.add(:participant_id, :no_declarations) if application&.declarations&.none?
    end

    def send_email
      ApplicationDeferredMailer.application_deferred_mail(
        to: application.user.email,
        full_name: application.user.full_name,
        provider_name: application.lead_provider.name,
        course_name: application.course.name,
        ecf_id: application.ecf_id,
      ).deliver_later
    end
  end
end
