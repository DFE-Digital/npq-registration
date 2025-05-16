FactoryBot.define do
  factory :revert_applications_to_pending_bulk_operation, class: BulkOperation::RevertApplicationsToPending do
    transient do
      application_ecf_ids { [SecureRandom.uuid] }
    end

    admin { create(:admin) }

    after(:build) do |bulk_operation, evaluator|
      tempfile = Tempfile.new.tap do |file|
        file.write(evaluator.application_ecf_ids.join("\n"))
        file.rewind
      end
      bulk_operation.file.attach(tempfile.open)
    end
  end
end
