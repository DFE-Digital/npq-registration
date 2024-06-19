class Contract < ApplicationRecord
  belongs_to :statement
  belongs_to :course
end
