class ChangeApplicationsLeadProviderApprovalStatusToEnum < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      ALTER TABLE applications
      ALTER COLUMN lead_provider_approval_status TYPE lead_provider_approval_statuses
      USING lead_provider_approval_status::lead_provider_approval_statuses
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE applications
      ALTER COLUMN lead_provider_approval_status TYPE text
    SQL
  end
end
