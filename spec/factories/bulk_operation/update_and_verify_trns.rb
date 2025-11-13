FactoryBot.define do
  factory :update_and_verify_trns_bulk_operation, class: BulkOperation::UpdateAndVerifyTrns do
    admin { create(:admin) }
  end
end
