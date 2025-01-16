class ChangeAPITokensLeadProviderIdOptional < ActiveRecord::Migration[7.1]
  def change
    change_column_null :api_tokens, :lead_provider_id, true
    add_check_constraint :api_tokens, "lead_provider_id IS NOT NULL AND scope = 'lead_provider' OR lead_provider_id IS NULL"

    reversible do |direction|
      direction.down do
        APIToken.where(lead_provider: nil).destroy_all
      end
    end
  end
end
