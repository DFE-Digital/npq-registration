class User < ApplicationRecord
  devise :database_authenticatable

  has_many :applications

  def null_user?
    false
  end
end
