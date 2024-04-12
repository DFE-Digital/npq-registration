module Migration::Ecf
  class ParticipantProfile < BaseRecord
    self.inheritance_column = nil

    belongs_to :teacher_profile
    belongs_to :schedule, class_name: "Finance::Schedule"
    has_one :user, through: :teacher_profile
    has_one :npq_application, foreign_key: :id

    default_scope { where(type: "ParticipantProfile::NPQ") }
  end
end
