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
        application.deferred!
        participant.reload
      end

      true
    end

  private

    def not_withdrawn
      errors.add(:participant_id, :already_withdrawn) if application&.withdrawn?
    end

    def not_already_deferred
      errors.add(:participant_id, :already_deferred) if application&.deferred?
    end

    def has_declarations
      errors.add(:participant_id, :no_declarations) if application&.declarations&.none?
    end
  end
end
