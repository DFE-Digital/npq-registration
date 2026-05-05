class OauthToken < ApplicationRecord
  belongs_to :user

  enum :token_type, {
    refresh_token: "refresh_token",
  }

  encrypts :token

  validates :token, presence: true
  validates :token_updated_at, presence: true
  validates :user_id, uniqueness: { scope: :token_type }
end
