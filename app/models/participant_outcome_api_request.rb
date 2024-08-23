class ParticipantOutcomeAPIRequest < ApplicationRecord
  belongs_to :participant_outcome

  validates :ecf_id, presence: true, uniqueness: { case_sensitive: false }
end
