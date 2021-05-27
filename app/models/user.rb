class User < ApplicationRecord
  devise :database_authenticatable

  def null_user?
    false
  end
end
