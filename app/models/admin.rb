class Admin < ApplicationRecord
  validates :full_name, presence: true, length: { maximum: 64 }
  validates :email, presence: true, length: { maximum: 64 }
end
