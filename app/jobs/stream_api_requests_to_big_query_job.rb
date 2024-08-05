require "google/cloud/bigquery"

class StreamApiRequestsToBigQueryJob < ApplicationJob
  include ActionController::HttpAuthentication::Token

  queue_as :low_priority

  def perform(request_data, response_data, status_code, created_at)
    return if table.nil?

    request_data = request_data.with_indifferent_access
    response_data = response_data.with_indifferent_access
    request_headers = request_data.fetch(:headers, {})
    token = auth_token(request_headers.delete("HTTP_AUTHORIZATION"))
    lead_provider = token.is_a?(APIToken) ? token.lead_provider : nil

    response_headers = response_data[:headers]
    response_body = response_data[:body]

    rows = [
      {
        request_path: request_data[:path],
        status_code:,
        request_headers:,
        request_method: request_data[:method],
        request_body: request_body(request_data),
        response_body: response_hash(response_body, status_code),
        response_headers:,
        lead_provider: lead_provider&.name,
        created_at:,
      }.stringify_keys,
    ]

    table.insert(rows, ignore_unknown: true)
  end

private

  def table
    bigquery = Google::Cloud::Bigquery.new
    dataset = bigquery.dataset "npq_registration", skip_lookup: true
    dataset.table "api_requests_#{Rails.env.downcase}"
  end

  AuthorizationStruct = Struct.new(:authorization)

  def auth_token(auth_header)
    return if auth_header.blank?

    token, _options = token_and_options(AuthorizationStruct.new(auth_header))
    APIToken.find_by_unhashed_token(token)
  end

  def response_hash(response_body, status)
    return {} unless status > 299
    return {} unless response_body

    JSON.parse(response_body)
  rescue JSON::ParserError
    { body: "#{status} did not respond with JSON" }
  end

  def request_body(request_data)
    if request_data[:body].present?
      JSON.parse(request_data[:body])
    else
      request_data[:params]
    end
  rescue JSON::ParserError
    { error: "request data did not contain valid JSON" }
  end
end
