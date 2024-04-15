class CreateLeadProviderApprovalStatusesEnum < ActiveRecord::Migration[7.1]
  def change
    create_enum :lead_provider_approval_statuses, %w[pending accepted rejected]
  end
end
