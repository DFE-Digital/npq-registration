# frozen_string_literal: true

class BulkOperation::BulkRejectApplications
  attr_reader :application_ecf_ids, :bulk_operation

  def initialize(application_ecf_ids:, bulk_operation:)
    @application_ecf_ids = application_ecf_ids
    @bulk_operation = bulk_operation
  end

  def run!
    result = {}
    ActiveRecord::Base.transaction do
      result = application_ecf_ids.each_with_object({}) do |application_ecf_id, hash|
        application = Application.find_by(ecf_id: application_ecf_id)
        reject_service = Applications::Reject.new(application:)
        success = reject_service.reject
        hash[application_ecf_id] = outcome(success, application, reject_service.errors)
      end
      bulk_operation.update!(result: result.to_json, finished_at: Time.zone.now)
    end

    result
  end

private

  def outcome(success, application, errors)
    return "Not found" if application.nil?
    return "Changed to rejected" if success

    errors.full_messages.to_sentence
  end
end
