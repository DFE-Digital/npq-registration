class Admin < ApplicationRecord
  validates :full_name, presence: true, length: { maximum: 64 }
  validates :email, presence: true, length: { maximum: 64 }

  # Whether this user has admin access to the feature flagging interface
  def flipper_access?
    super_admin?
  end
end
