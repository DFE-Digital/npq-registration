class AddScopeToAPITokens < ActiveRecord::Migration[7.1]
  def change
    create_enum :api_token_scopes, %w[lead_provider teacher_record_service]

    add_column :api_tokens, :scope, :enum, enum_type: "api_token_scopes", default: "lead_provider"
    change_column_null :api_tokens, :lead_provider_id, true

    add_check_constraint(
      :api_tokens,
      "(lead_provider_id IS NOT NULL AND scope = 'lead_provider') OR (lead_provider_id IS NULL AND scope <> 'lead_provider')",
    )

    reversible do |direction|
      direction.down do
        APIToken.where(lead_provider: nil).destroy_all
      end
    end
  end
end
