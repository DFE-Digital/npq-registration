class BulkOperation::RevertApplicationsToPending < BulkOperation
  def run!
    result = {}
    ActiveRecord::Base.transaction do
      result = ids_to_update.index_with do |application_ecf_id|
        process_csv_row(application_ecf_id)
      end
      update!(result: result.to_json, finished_at: Time.zone.now)
    end

    result
  end

private

  def process_csv_row(application_ecf_id)
    application = Application.find_by(ecf_id: application_ecf_id)
    revert_to_pending = Applications::RevertToPending.new(application:, change_status_to_pending: "yes")
    success = revert_to_pending.revert
    outcome(success, application, revert_to_pending.errors)
  end

  def outcome(success, application, errors)
    return "Not found" if application.nil?
    return "Changed to pending" if success

    errors.full_messages.to_sentence
  end
end
