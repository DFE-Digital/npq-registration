# frozen_string_literal: true

module OneOff
  class BulkChangeApplicationsToPending
    attr_reader :application_ecf_ids

    def initialize(application_ecf_ids:)
      @application_ecf_ids = application_ecf_ids
    end

    def run!(dry_run: true)
      result = {}
      ActiveRecord::Base.transaction do
        result = application_ecf_ids.each_with_object({}) do |application_ecf_id, hash|
          application = Application.find_by(ecf_id: application_ecf_id)
          revert_to_pending = Applications::RevertToPending.new(application:, change_status_to_pending: "yes")
          success = application && revert_to_pending.revert
          hash[application_ecf_id] = outcome(success, application, revert_to_pending.errors)
        end

        raise ActiveRecord::Rollback if dry_run
      end

      result
    end

  private

    def outcome(success, application, errors)
      return "Not found" if application.nil?
      return "Changed to pending" if success

      errors.map(&:message).join(", ")
    end
  end
end
