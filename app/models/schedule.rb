class Schedule < ApplicationRecord
  belongs_to :course_group
  belongs_to :cohort

  validates \
    :name,
    :declaration_start_date,
    :starts_on,
    :ends_on, presence: true
end
