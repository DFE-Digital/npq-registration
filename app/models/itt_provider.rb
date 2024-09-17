class IttProvider < ApplicationRecord
  include Disableable

  validates :legal_name,
            presence: true,
            uniqueness: true
  validates :operating_name,
            presence: true

  scope :currently_approved, -> { where(approved: true) }
end
