class CourseGroup < ApplicationRecord
  has_many :courses

  validates :name, presence: { message: "Enter a unique course group name" }, uniqueness: { message: "Course name already exist, enter a unique name" }
end
