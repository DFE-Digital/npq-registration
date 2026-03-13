FactoryBot.define do
  factory :upload_eligibility_list_bulk_operation, class: BulkOperation::UploadEligibilityList do
    admin { create(:admin) }
    eligibility_list_type { "EligibilityList::Pp50School" }

    after(:build) do |bulk_operation|
      content = <<~CSV
        PP50 School URN
        100000
      CSV

      file = Tempfile.new.tap do |file|
        file.write(content)
        file.rewind
      end

      bulk_operation.file.attach(file.open) unless bulk_operation.file.attached?
    end
  end
end
