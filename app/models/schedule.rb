class Schedule < ApplicationRecord
  belongs_to :course
  belongs_to :cohort
end
