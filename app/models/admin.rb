class Admin < ApplicationRecord
  validates :full_name,
            presence: { message: "Enter a full name" },
            length: { maximum: 64, message: "Full name must be shorter than 64 characters" }

  validates :email, presence: true, length: { maximum: 64 }

  # Whether this user has admin access to the feature flagging interface
  def flipper_access?
    super_admin?
  end
end
