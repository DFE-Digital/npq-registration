class Setting < ApplicationRecord
  validates :course_start_date, presence: true

  def self.course_start_date
    Setting.first.course_start_date
  end
end
