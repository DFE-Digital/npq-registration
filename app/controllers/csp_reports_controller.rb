# frozen_string_literal: true

class CspReportsController < ApplicationController
  skip_before_action :verify_authenticity_token

  CSP_KEYS = %w[
    blocked-uri
    disposition
    document-uri
    effective-directive
    original-policy
    referrer
    script-sample
    status-code
    violated-directive
  ].freeze
  MAX_ENTRY_LENGTH = 2_000

  def create
    request_body = request.body ? request.body.dup.tap(&:rewind).read : "{}"
    json = JSON.parse(request_body)
    report = (json["csp-report"] || {})
               .slice(*CSP_KEYS)
               .transform_values { |v| v.truncate(MAX_ENTRY_LENGTH) }

    trace_csp_violation(report) unless report.empty?

    head :ok
  end

private

  def trace_csp_violation(report)
    Rails.logger.error({ "csp-report" => report })
  end
end
