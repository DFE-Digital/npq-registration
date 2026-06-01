class OauthToken < ApplicationRecord
  REFRESH_LIFETIME = 72.hours.freeze

  belongs_to :user

  enum :token_type, {
    refresh_token: "refresh_token",
  }

  scope :needs_refresh,
        -> { refresh_token.where(token_updated_at: ...REFRESH_LIFETIME.ago) }

  encrypts :token

  validates :token, presence: true
  validates :token_updated_at, presence: true
  validates :user_id, uniqueness: { scope: :token_type }

  def store!(token)
    update!(token:,
            token_updated_at: Time.current)
  end
end
