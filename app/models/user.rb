class User < ApplicationRecord
  has_many :applications

  def null_user?
    false
  end
end
