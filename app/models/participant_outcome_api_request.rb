class ParticipantOutcomeAPIRequest < ApplicationRecord
  belongs_to :participant_outcome

  validates :ecf_id,
            presence: { message: "Enter an ECF ID" },
            uniqueness: {
              case_sensitive: false,
              message: "ECF ID must be unique",
            }
end
