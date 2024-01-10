class CourseGroup < ApplicationRecord
  has_many :courses
  has_many :schedules
  validates :name, presence: true
end
