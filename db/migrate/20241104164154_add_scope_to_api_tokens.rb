class AddScopeToAPITokens < ActiveRecord::Migration[7.1]
  def change
    add_column :api_tokens, :scope, :string
    change_column_null :api_tokens, :lead_provider_id, true
  end
end
