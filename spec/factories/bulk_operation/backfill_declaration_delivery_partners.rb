FactoryBot.define do
  factory :backfill_declaration_delivery_partners_bulk_operation, class: BulkOperation::BackfillDeclarationDeliveryPartners do
    admin { create(:admin) }
  end
end
