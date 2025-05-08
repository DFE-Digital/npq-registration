FactoryBot.define do
  factory :update_and_verify_trns_bulk_operation, class: BulkOperation::UpdateAndVerifyTrns do
    transient do
      trns_to_update { [[SecureRandom.uuid, "1234567"]] }
    end

    admin { create(:admin) }

    after(:build) do |bulk_operation, evaluator|
      tempfile = Tempfile.new.tap do |file|
        file.write("#{BulkOperation::UpdateAndVerifyTrns::FILE_HEADERS.join(",")}\n")
        file.write(evaluator.trns_to_update.map { |columns| columns.join(",") }.join("\n"))
        file.rewind
      end
      bulk_operation.file.attach(tempfile.open)
    end
  end
end
