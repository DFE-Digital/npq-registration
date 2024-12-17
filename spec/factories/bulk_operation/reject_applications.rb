FactoryBot.define do
  factory :reject_applications, class: BulkOperation::RejectApplications do
    admin { create(:admin) }
  end
end
