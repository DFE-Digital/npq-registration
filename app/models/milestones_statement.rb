class MilestonesStatement < ApplicationRecord
  belongs_to :milestone
  belongs_to :statement

  validate :statement_must_be_output_fee_true
  # TODO: validate only one statement date per milestone
  # TODO: validate statements for all lead providers exist for the statement date

private

  def statement_must_be_output_fee_true
    return if statement&.output_fee?

    errors.add(:statement, :must_be_output_fee_true)
  end
end
