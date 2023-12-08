class Declaration < ApplicationRecord
  belongs_to :application
  belongs_to :course
  belongs_to :lead_provider
  belongs_to :user
end
