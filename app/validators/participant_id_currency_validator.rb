# frozen_string_literal: true

class ParticipantIdCurrencyValidator < ActiveModel::Validator
  def validate(record)
    return unless (participant_id_change = ParticipantIdChange.find_by(from_participant_id: record.participant_id))

    record.errors.add(:participant_id, :changed, **participant_id_change.i18n_params)
  end
end
