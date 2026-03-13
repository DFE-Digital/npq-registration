FactoryBot.define do
  factory :upload_eligibility_list_bulk_operation, class: BulkOperation::UploadEligibilityList::Pp50School do
    admin { create(:admin) }

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
