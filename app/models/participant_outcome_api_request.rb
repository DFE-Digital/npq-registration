class ParticipantOutcomeAPIRequest < ApplicationRecord
  belongs_to :participant_outcome

  validates :ecf_id, uniqueness: { case_sensitive: false }
end
