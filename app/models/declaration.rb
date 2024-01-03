# Declaration
#
# * Made by lead providers via the API
# * There can be multiple per application
# * Must persist even if application state is reverted to pending
# * There’s a limit to how many there can be per application
#   - by type
#   - by state
# * Needs to allow providers to correct errors
# * Shouldn’t result in the same thing being paid for more than once
# * participant_declaration_attempts
# * Uplifts - some declarations may result in an additional payment based on the
#   school’s sparsity/pupil premium
# * When made it’s attached (via statement line item) to the ‘open’ statement for that contract
# * If we drop schedules/milestones we might want to add some kind of validation
#   to prevent them from being made too early/late
# * A declaration can change into many ‘states’ refer to here https://docs.google.com/presentation/d/1UMFxAZTs8r0_K7VlEZSxx2MYzB_9yG36gQrPgLy5R_Q/edit?usp=sharing
class Declaration < ApplicationRecord
  belongs_to :application
  has_many :outcomes

  # validates :declaration_date - this depends on the schedule
  # theoretically the supplier can make multiple declarations at once, that *is* valid
  # must exist within the current schedule's bounds
  #
  # must be between the start_date and the milestone_date
  # TODO: clarify what the relationship between the declaration_date and
  #       milestone payment date is

  STATES = %w[submitted eligible ineligible payable voided paid awaiting_clawback clawed_back].freeze
  validates :state, inclusion: { in: STATES }
end
