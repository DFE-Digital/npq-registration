class OauthToken < ApplicationRecord
  belongs_to :user

  enum :token_type, {
    refresh: "refresh",
  }
end
