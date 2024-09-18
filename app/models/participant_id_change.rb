# frozen_string_literal: true

class ParticipantIdChange < ApplicationRecord
  belongs_to :user
  belongs_to :from_participant, class_name: "User", primary_key: "ecf_id"
  belongs_to :to_participant, class_name: "User", primary_key: "ecf_id"

  validates :user, :from_participant, :to_participant, presence: true
end
