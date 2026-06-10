class BulkOperation::UploadEligibilityList < BulkOperation
  validates :file, presence: true

  def run!
    ActiveRecord::Base.transaction do
      eligibility_list_type_class.delete_all
      csv_from_active_storage.each do |row|
        identifier = identifier(row)&.strip
        eligibility_list_type_class.find_or_create_by!(identifier:) if identifier.present?
      end
      update!(finished_at: Time.zone.now)
    end
  rescue StandardError => e
    update!(finished_at: Time.zone.now, result: "There was an unexpected error processing the file: #{e.message}")
    Sentry.capture_exception(e)
  end

private

  def headers?
    true
  end

  def file_headers
    eligibility_list_type_class::IDENTIFIER_CSV_HEADERS
  end

  def identifier(row)
    row[eligibility_list_type_class::IDENTIFIER_CSV_HEADERS.last].presence || row[eligibility_list_type_class::IDENTIFIER_CSV_HEADERS.first]
  end
end
