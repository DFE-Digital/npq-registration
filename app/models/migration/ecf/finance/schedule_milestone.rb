# frozen_string_literal: true

module Migration::Ecf::Finance
  class ScheduleMilestone < Migration::Ecf::BaseRecord
    self.table_name = "schedule_milestones"

    belongs_to :schedule
    belongs_to :milestone
  end
end
