module Migration::Ecf
  class ParticipantIdChange < BaseRecord
    belongs_to :user
    belongs_to :from_participant, class_name: "User"
    belongs_to :to_participant, class_name: "User"
  end
end
