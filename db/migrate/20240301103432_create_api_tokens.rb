class CreateAPITokens < ActiveRecord::Migration[7.1]
  def change
    create_table :api_tokens do |t|
      t.references :lead_provider, null: false, foreign_key: true
      t.string :hashed_token, null: false
      t.datetime :last_used_at

      t.index :hashed_token, unique: true

      t.timestamps
    end
  end
end
