# Schedule
#
# * has many milestones, varying by type of npq course (e.g. a specialist course
#   has 3 milestones)
# * every course type (npq specialist, npq leadership, ehco / aso) has it’s own
#   schedule - see here:
#   https://manage-training-for-early-career-teachers.education.gov.uk/finance/schedules
# * "Milestone validation", which depends on each schedule milestone having a set
#   start and end date, is an ECF thing to ensure declarations are made/paid when
#   DfE mandates them to be. For example, if today’s date is before a start date
#   for a given declaration, then API will reject a request with error message to
#   effect of "too early to declare". NPQ does not have same level of validation as
#   ECF, but inherited the schedule structure.
class Schedule < ApplicationRecord
  belongs_to :cohort
end
