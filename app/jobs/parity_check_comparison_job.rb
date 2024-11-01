class ParityCheckComparisonJob < ApplicationJob
  queue_as :high_priority

  def perform(lead_provider:, method:, path:, options:)
    client = Migration::ParityCheck::Client.new(lead_provider:, method:, path:, options:)

    client.make_requests do |ecf_result, npq_result, formatted_path, page|
      save_comparison!(lead_provider:, path: formatted_path, method:, page:, ecf_result:, npq_result:, options:)
    end

    Migration::ParityCheck.finalise!
  end

private

  def save_comparison!(lead_provider:, path:, method:, page:, ecf_result:, npq_result:, options:)
    Migration::ParityCheck::ResponseComparison.create!(
      lead_provider:,
      request_path: path,
      request_method: method,
      ecf_response_status_code: ecf_result[:response].code,
      npq_response_status_code: npq_result[:response].code,
      ecf_response_body: ecf_result[:response].body,
      npq_response_body: npq_result[:response].body,
      ecf_response_time_ms: ecf_result[:response_ms],
      npq_response_time_ms: npq_result[:response_ms],
      exclude: options[:exclude],
      page:,
    )
  end
end
