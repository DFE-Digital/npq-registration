class AddLeadProviderApprovalStatusToApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :applications, :lead_provider_approval_status, :text, null: false, default: "pending"
  end
end
