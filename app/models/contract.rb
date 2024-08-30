class Contract < ApplicationRecord
  belongs_to :statement
  belongs_to :course
  belongs_to :contract_template

  validates :course_id, uniqueness: { scope: :statement_id, message: "Can only have one contract for statement and course" }
end
