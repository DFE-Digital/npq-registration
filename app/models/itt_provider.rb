class IttProvider < ApplicationRecord
  validates :legal_name,
            presence: true,
            uniqueness: true
  validates :operating_name,
            presence: true

  default_scope { where(disabled_at: nil) }

  scope :currently_approved, -> { where(approved: true) }
end
