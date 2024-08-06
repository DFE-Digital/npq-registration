# frozen_string_literal: true

module Participants
  class Resume < Action
    validate :not_already_active

    def resume
      return false if invalid?

      ActiveRecord::Base.transaction do
        create_application_state!
        application.active!
        participant.reload
      end

      true
    end

  private

    def not_already_active
      errors.add(:participant_id, :already_active) if application&.active?
    end
  end
end
