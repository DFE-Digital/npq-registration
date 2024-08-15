# frozen_string_literal: true

module Participants
  class Withdraw < Action
    WITHDRAWAL_REASONS = %w[
      insufficient-capacity-to-undertake-programme
      personal-reason-health-or-pregnancy-related
      personal-reason-moving-school
      personal-reason-other
      insufficient-capacity
      change-in-developmental-or-personal-priorities
      change-in-school-circumstances
      change-in-school-leadership
      quality-of-programme-structure-not-suitable.
      quality-of-programme-content-not-suitable
      quality-of-programme-facilitation-not-effective
      quality-of-programme-accessibility
      quality-of-programme-other
      programme-not-appropriate-for-role-and-cpd-needs
      started-in-error
      expected-commitment-unclear
      other
    ].freeze

    attribute :reason

    validates :reason, inclusion: { in: WITHDRAWAL_REASONS }, allow_blank: false
    validate :not_withdrawn
    validate :has_started_declarations

    def withdraw
      return false if invalid?

      ActiveRecord::Base.transaction do
        create_application_state!(state: :withdrawn, reason:)
        application.withdrawn_training_status!
        participant.reload
      end

      true
    end

  private

    def not_withdrawn
      errors.add(:participant_id, :already_withdrawn) if application&.withdrawn_training_status?
    end

    def has_started_declarations
      errors.add(:participant_id, :no_started_declarations) unless application&.declarations&.any?(&:started_declaration_type?)
    end
  end
end
