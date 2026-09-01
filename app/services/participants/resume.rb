# frozen_string_literal: true

module Participants
  class Resume < Action
    validate :not_already_active

    def resume
      return false if invalid?

      previously_withdrawn = application.withdrawn_training_status?

      ActiveRecord::Base.transaction do
        create_application_state!
        application.active_training_status!
        participant.reload
        # NPQ-3934: deferred to active notifications are turned off while
        # providers clean up their course outcome data. Remove the condition to
        # turn them back on.
        send_email if previously_withdrawn
      end

      true
    end
    alias_method :call, :resume

  private

    def not_already_active
      errors.add(:participant_id, :already_active) if application&.active_training_status?
    end

    def send_email
      return if application.user.email.blank?
      return if application.completed_declarations?

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
