FactoryBot.define do
  factory :reject_applications_bulk_operation, class: BulkOperation::RejectApplications do
    transient do
      application_ecf_ids { [SecureRandom.uuid] }
    end

    admin { create(:admin) }
  end
end
