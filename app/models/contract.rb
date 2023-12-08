class Contract < ApplicationRecord
  belongs_to :statement
  belongs_to :course
  belongs_to :cohort
  belongs_to :lead_provider
end
