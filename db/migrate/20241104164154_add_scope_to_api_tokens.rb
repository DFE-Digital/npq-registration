class AddScopeToAPITokens < ActiveRecord::Migration[7.1]
  def change
    add_column :api_tokens, :scope, :string
    change_column_null :api_tokens, :lead_provider_id, true

    reversible do |direction|
      direction.up do
        execute <<-SQL
          UPDATE api_tokens SET scope = 'lead_provider';
        SQL
      end
    end
  end
end
