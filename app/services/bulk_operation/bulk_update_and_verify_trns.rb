# frozen_string_literal: true

class BulkOperation::BulkUpdateAndVerifyTrns
  attr_reader :trns_to_update, :bulk_operation

  def initialize(bulk_operation:)
    @bulk_operation = bulk_operation
  end

  def run!
    result = {}
    ActiveRecord::Base.transaction do
      result = bulk_operation.ids_to_update.each_with_object({}) do |csv_row, outcomes_hash|
        outcomes_hash[user_ecf_id(csv_row)] = process_csv_row(csv_row)
      end
      bulk_operation.update!(result: result.to_json, finished_at: Time.zone.now)
    end

    result
  end

private

  def process_csv_row(csv_row)
    new_trn = csv_row[BulkOperation::UpdateAndVerifyTrns::FILE_HEADER_UPDATED_TRN]
    user = User.find_by(ecf_id: user_ecf_id(csv_row))
    change_trn_service = Participants::ChangeTrn.new(user:, trn: new_trn)
    success = change_trn_service.change_trn
    outcome(success, change_trn_service.errors)
  end

  def outcome(success, errors)
    return "TRN updated and verified" if success

    errors.full_messages.to_sentence
  end

  def user_ecf_id(csv_row)
    csv_row[BulkOperation::UpdateAndVerifyTrns::FILE_HEADER_USER_ID]
  end
end
