FactoryBot.define do
  factory :revert_applications_to_pending_bulk_operation, class: BulkOperation::RevertApplicationsToPending do
    transient do
      application_ecf_ids { [SecureRandom.uuid] }
    end

    admin { create(:admin) }
  end
end
