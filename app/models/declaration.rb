class Declaration < ApplicationRecord
  STATES = %w[submitted eligible payable paid voided ineligible awaiting_clawback clawed_back].freeze

  belongs_to :application
  belongs_to :course
  belongs_to :lead_provider
  belongs_to :user

  validates :application_id, presence: true
  validates :course_id, presence: true
  validates :lead_provider_id, presence: true
  validates :user_id, presence: true

  validates :state, inclusion: { in: STATES }
end
