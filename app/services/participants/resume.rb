# frozen_string_literal: true

module Participants
  class Resume < Action
    validate :not_already_active

    def resume
      return false if invalid?

      ActiveRecord::Base.transaction do
        create_application_state!
        application.active_training_status!
        participant.reload
        send_email
      end

      true
    end
    alias_method :call, :resume

  private

    def not_already_active
      errors.add(:participant_id, :already_active) if application&.active_training_status?
    end

    def send_email
      ApplicationResumedMailer.application_resumed_mail(
        to: application.user.email,
        full_name: application.user.full_name,
        provider_name: application.lead_provider.name,
        course_name: application.course.name,
        ecf_id: application.ecf_id,
      ).deliver_later
    end
  end
end
