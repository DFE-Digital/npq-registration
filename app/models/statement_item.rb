# StatementItem
#
# * Is the join table of a many-to-many relation between declarations and
#   statements
# * A declaration could have two statement line items max, one for the original
#   payment and a potential second one if it’s clawed back
class StatementItem < ApplicationRecord
  STATES = %w[eligible payable paid voided ineligible awaiting_clawback clawed_back].freeze

  belongs_to :statement
  belongs_to :declaration
  belongs_to :clawed_back_by, class_name: "StatementItem", optional: true

  validates :state, inclusion: { in: STATES }
  validates :clawed_back_by, presence: true, if: -> { state == "clawed_back" }
end
