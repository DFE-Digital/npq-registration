class BulkOperation::UploadEligibilityList < BulkOperation
  attr_accessor :eligibility_list_type

  validates :file, presence: true

  def run!(eligibility_list_type:)
    @eligibility_list_type = eligibility_list_type
    ActiveRecord::Base.transaction do
      eligibility_list_type_class.delete_all
      csv_from_active_storage.each do |row|
        eligibility_list_type_class.find_or_create_by!(identifier: identifier(row).strip)
      end
      update!(finished_at: Time.zone.now)
    end
  rescue StandardError => e
    update!(finished_at: Time.zone.now, result: "#{e.class}: #{e.message}")
  end

private

  def headers?
    true
  end

  def file_headers
    eligibility_list_type_class::IDENTIFIER_CSV_HEADERS
  end

  def eligibility_list_type_class
    @eligibility_list_type_class ||= eligibility_list_type.constantize
  end

  def identifier(row)
    row[eligibility_list_type_class::IDENTIFIER_CSV_HEADERS.last].presence || row[eligibility_list_type_class::IDENTIFIER_CSV_HEADERS.first]
  end
end
