class User < ApplicationRecord
  has_many :applications, dependent: :destroy

  validates :email, uniqueness: true

  def null_user?
    false
  end
end
