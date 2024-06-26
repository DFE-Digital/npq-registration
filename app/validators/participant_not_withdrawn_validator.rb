# frozen_string_literal: true

class ParticipantNotWithdrawnValidator < ActiveModel::Validator
  def validate(record)
    return if record.errors.any?

    validate_withdrawals(record)
  end

private

  def validate_withdrawals(record)
    return unless record.application.present? && (latest_state = latest_participant_application_state(record))
    return unless latest_state.withdrawn? && latest_state.created_at <= record.declaration_date

    record
      .errors
      .add(:participant_id, :declaration_must_be_before_withdrawal_date, withdrawal_date: latest_state.created_at.rfc3339)
  end

  def latest_participant_application_state(record)
    record.application
      .application_states
      .for_lead_provider(record.lead_provider)
      .most_recent
      .first
  end
end
