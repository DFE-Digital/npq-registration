class CreateOauthTokens < ActiveRecord::Migration[8.1]
  def change
    create_enum :oauth_token_types, %w[refresh]

    create_table :oauth_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.enum :token_type, enum_type: :oauth_token_types, null: false, default: "refresh"
      t.timestamp :last_updated_token_at
      t.string :token, null: false

      t.timestamps
    end
  end
end
