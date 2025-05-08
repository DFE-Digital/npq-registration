class BulkOperation::RejectApplications < BulkOperation
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
    reject_service = Applications::Reject.new(application:)
    success = reject_service.reject
    outcome(success, application, reject_service.errors)
  end

  def outcome(success, application, errors)
    return "Not found" if application.nil?
    return "Changed to rejected" if success

    errors.full_messages.to_sentence
  end
end
