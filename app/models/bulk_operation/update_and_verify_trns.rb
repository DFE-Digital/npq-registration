class BulkOperation::UpdateAndVerifyTrns < BulkOperation
  HEADERS = true
  FILE_HEADER_USER_ID = "User ID".freeze
  FILE_HEADER_UPDATED_TRN = "Updated TRN".freeze
  FILE_HEADERS = [FILE_HEADER_USER_ID, FILE_HEADER_UPDATED_TRN].freeze

  def ids_to_update
    file.open { CSV.read(_1, headers: true) }
  end

private

  def check_format
    csv = CSV.read(attached_file, headers: true)

    errors.add(:file, :empty) if csv.count.zero?

    if csv.headers != FILE_HEADERS
      errors.add(:file, :invalid)
    end
  rescue CSV::MalformedCSVError
    errors.add(:file, :malformed)
  end
end
