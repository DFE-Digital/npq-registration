class Milestone < ApplicationRecord
  belongs_to :schedule

  # start_date - beginning of schedule
  # payment_date - date on which payment is made
  # milestone_date - end of schedule
end
