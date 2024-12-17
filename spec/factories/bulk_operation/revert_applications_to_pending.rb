FactoryBot.define do
  factory :revert_applications_to_pending_bulk_operation, class: BulkOperation::RevertApplicationsToPending do
    admin { create(:admin) }
  end
end
