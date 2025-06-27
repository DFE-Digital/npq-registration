# frozen_string_literal: true

class ParticipantIdChange < ApplicationRecord
  belongs_to :user

  validates :user, :from_participant_id, :to_participant_id, presence: true
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true

  def i18n_params
    { from_participant_id:, to_participant_id: }
  end
end
