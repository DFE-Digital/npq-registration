class User < ApplicationRecord
  has_many :applications

  validates :email, uniqueness: true

  def null_user?
    false
  end
end
