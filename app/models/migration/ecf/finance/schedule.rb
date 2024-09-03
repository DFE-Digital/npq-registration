module Migration::Ecf::Finance
  class Schedule < Migration::Ecf::BaseRecord
    self.inheritance_column = nil

    belongs_to :cohort
    has_many :participant_profiles
    has_many :schedule_milestones, class_name: "Migration::Ecf::Finance::ScheduleMilestone"
    has_many :milestones

    default_scope { where("schedules.type ilike ?", "Finance::Schedule::NPQ%") }
  end
end
