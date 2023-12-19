# Milestone
#
# * represents the date from which the declaration type is valid and if/when
#   the declaration_date must be set between
class Milestone < ApplicationRecord
  belongs_to :schedule

  # start_date - beginning of schedule
  # payment_date - date on which payment is made
  # milestone_date - end of schedule
end
