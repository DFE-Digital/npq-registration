FactoryBot.define do
  factory :reject_applications_bulk_operation, class: BulkOperation::RejectApplications do
    admin { create(:admin) }
  end
end
