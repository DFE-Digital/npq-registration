class AddScopeToAPITokens < ActiveRecord::Migration[7.1]
  def change
    add_column :api_tokens, :scope, :string, default: "lead_provider", null: false

    reversible do |direction|
      direction.up do
        execute <<-SQL
          UPDATE api_tokens SET scope = 'lead_provider';
        SQL
      end
    end
  end
end
