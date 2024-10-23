# frozen_string_literal: true

class ParticipantIdChange < ApplicationRecord
  belongs_to :user

  validates :user, :from_participant_id, :to_participant_id, presence: true
  # TODO: remove "allow_nil" and add default value "gen_random_uuid()" and constraints into the DB after separation
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true
end
