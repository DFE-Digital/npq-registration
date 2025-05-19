class BulkOperation::UpdateAndVerifyTrns < BulkOperation
  HEADERS = true
  FILE_HEADER_USER_ID = "User ID".freeze
  FILE_HEADER_UPDATED_TRN = "Updated TRN".freeze
  FILE_HEADERS = [FILE_HEADER_USER_ID, FILE_HEADER_UPDATED_TRN].freeze

  def ids_to_update
    file.open { CSV.read(_1, headers: true) }
  end

  def run!
    result = {}
    ActiveRecord::Base.transaction do
      result = ids_to_update.each_with_object({}) do |csv_row, outcomes_hash|
        outcomes_hash[user_ecf_id(csv_row)] = process_csv_row(csv_row)
      end
      update!(result: result.to_json, finished_at: Time.zone.now)
    end

    result
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

  def process_csv_row(csv_row)
    new_trn = csv_row[BulkOperation::UpdateAndVerifyTrns::FILE_HEADER_UPDATED_TRN]
    user = User.find_by(ecf_id: user_ecf_id(csv_row))
    change_trn_service = Participants::ChangeTrn.new(user:, trn: new_trn)
    success = change_trn_service.change_trn
    outcome(success, change_trn_service.errors)
  end

  def outcome(success, errors)
    return "TRN updated and verified" if success

    errors.messages.values.flatten.to_sentence
  end

  def user_ecf_id(csv_row)
    csv_row[BulkOperation::UpdateAndVerifyTrns::FILE_HEADER_USER_ID]
  end
end
