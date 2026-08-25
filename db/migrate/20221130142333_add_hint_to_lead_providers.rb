class AddHintToLeadProviders < ActiveRecord::Migration[6.1]
  def up
    add_column :lead_providers, :hint, :string

    school_led_network_lead_provider = LeadProvider.find_by(ecf_id: "bc5e4e37-1d64-4149-a06b-ad10d3c55fd0")

    school_led_network_lead_provider&.update!(
      hint: "You can only register with this provider if you already started your NPQ with them in October 2022.",
    )
  end

  def down
    remove_column :lead_providers, :hint
  end
end
