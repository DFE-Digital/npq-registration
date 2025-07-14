FactoryBot.define do
  factory :submit_declarations_bulk_operation, class: BulkOperation::SubmitDeclarations do
    admin { create(:admin) }
  end
end
