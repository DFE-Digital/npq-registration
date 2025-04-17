class BulkOperation::UpdateAndVerifyTrns < BulkOperation
  FILE_NUMBER_OF_COLUMNS = 2
  FILE_HEADERS = ["User ID", "Updated TRN"].freeze

private

  def check_format(string)
    CSV.parse(string, headers: true) do |row|
      if row.size != FILE_NUMBER_OF_COLUMNS || row.headers != FILE_HEADERS
        errors.add(:file, :invalid)
        break
      end
    end
  rescue CSV::MalformedCSVError
    errors.add(:file, :malformed)
  end
end
