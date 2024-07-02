# frozen_string_literal: true

class ParticipantPresenceValidator < ActiveModel::Validator
  def validate(record)
    return if record.errors.any?

    has_participant?(record)
  end

private

  def has_participant?(record)
    return if record.participant.present?

    record.errors.add(:participant_id, :invalid_participant)
  end
end
