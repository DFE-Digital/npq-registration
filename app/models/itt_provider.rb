class IttProvider < ApplicationRecord
  validates :legal_name,
            presence: true,
            uniqueness: true
  validates :operating_name,
            presence: true
  validates :added,
            presence: true

  scope :currently_approved, -> { where(approved: true) }
end
