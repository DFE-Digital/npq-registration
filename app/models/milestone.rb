class Milestone < ApplicationRecord
  DECLARATION_TYPES = %w[started retained-1 retained-2 completed].freeze

  has_many :milestones_statements
  has_many :statements, through: :milestones_statements
  belongs_to :schedule

  default_scope { in_order_of(:declaration_type, DECLARATION_TYPES) }

  def statement_date
    statement = statements.first
    Date.new(statement.year, statement.month, 1) if statement
  end
end
