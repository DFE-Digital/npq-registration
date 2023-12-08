class Statement < ApplicationRecord
  belongs_to :cohort
  belongs_to :lead_provider
end
