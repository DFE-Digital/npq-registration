class CreateOauthTokens < ActiveRecord::Migration[8.0]
  def change
    create_enum :oauth_token_types, %w[refresh_token]

    create_table :oauth_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.enum :token_type, enum_type: "oauth_token_types", default: "refresh_token", null: false
      t.text :token, null: false
      t.datetime :token_updated_at, null: false
      t.timestamps
    end

    add_index :oauth_tokens, %i[user_id token_type], unique: true
    add_index :oauth_tokens, :token_updated_at
  end
end
