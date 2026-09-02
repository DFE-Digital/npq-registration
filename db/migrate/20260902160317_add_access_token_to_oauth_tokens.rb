class AddAccessTokenToOauthTokens < ActiveRecord::Migration[8.1]
  def change
    add_enum_value :oauth_token_types, "access_token"
  end
end
