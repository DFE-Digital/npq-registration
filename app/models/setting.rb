class Setting < ApplicationRecord
  validates :course_start_date, presence: true
end
