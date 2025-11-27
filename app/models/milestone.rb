class Milestone < ApplicationRecord
  has_paper_trail

  ALL_DECLARATION_TYPES = %w[started retained-1 retained-2 completed].freeze

  has_many :milestone_statements
  has_many :statements, through: :milestone_statements
  belongs_to :schedule

  scope :in_declaration_type_order, -> { order(:declaration_type) }

  def statement_date
    statement = statements.first
    Date.new(statement.year, statement.month, 1) if statement
  end
end
