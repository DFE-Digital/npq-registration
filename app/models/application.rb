class Application < ApplicationRecord
  belongs_to :user
  belongs_to :course
  belongs_to :lead_provider
end
