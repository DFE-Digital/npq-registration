class AddScopeToAPITokens < ActiveRecord::Migration[7.1]
  def change
    add_column :api_tokens, :scope, :string, default: "lead_provider", null: false
  end
end
