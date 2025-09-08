class Admin < ApplicationRecord
  has_many :bulk_operations

  validates :full_name, presence: true, length: { maximum: 64 }
  validates :email, presence: true, length: { maximum: 64 }

  def name_with_email
    "#{full_name} (#{email})"
  end
end
