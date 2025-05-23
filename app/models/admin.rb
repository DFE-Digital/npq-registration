class Admin < ApplicationRecord
  has_many :bulk_operations

  validates :full_name,
            presence: { message: "Enter a full name" },
            length: { maximum: 64, message: "Full name must be shorter than 64 characters" }

  validates :email,
            presence: { message: "Enter an email address" },
            length: { maximum: 64, message: "Email must be shorter than 64 characters" }
end
