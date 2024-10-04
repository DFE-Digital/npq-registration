class Admin < ApplicationRecord
  validates :full_name,
            presence: { message: "Enter a full name" },
            length: { maximum: 64, message: "Full name must be shorter than 64 characters" }

  validates :email,
            presence: { message: "Enter an email address" },
            length: { maximum: 64, message: "Email must be shorter than 64 characters" },
            uniqueness: { message: "An admin with this email address already exists" }

  # Whether this user has admin access to the feature flagging interface
  def flipper_access?
    super_admin?
  end
end
