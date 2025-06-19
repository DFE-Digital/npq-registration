FactoryBot.define do
  factory :update_and_verify_trns_bulk_operation, class: BulkOperation::UpdateAndVerifyTrns do
    transient do
      trns_to_update { [[SecureRandom.uuid, "1234567"]] }
    end

    admin { create(:admin) }
  end
end
