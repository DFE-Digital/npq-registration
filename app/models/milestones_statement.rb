class MilestonesStatement < ApplicationRecord
  has_paper_trail

  belongs_to :milestone
  belongs_to :statement

  validate :statement_must_be_output_fee_true
  validate :unique_statement_date_per_milestone

private

  def statement_must_be_output_fee_true
    return if statement&.output_fee?

    errors.add(:statement, :must_be_output_fee_true)
  end

  def unique_statement_date_per_milestone
    return unless milestone && statement

    existing_statements = milestone.statements.where.not(year: statement.year, month: statement.month)
    if existing_statements.any?
      errors.add(:statement, :duplicate_statement_date_for_milestone)
    end
  end
end
