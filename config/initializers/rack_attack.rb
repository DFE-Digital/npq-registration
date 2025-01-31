# frozen_string_literal: true

# Throttle general requests by IP
class Rack::Attack
  PROTECTED_ROUTES = [
    "/registration/qualified_teacher_check",
    "/registration/qualified_teacher_check/change",
    "/registration/qualified-teacher-check",
    "/registration/qualified-teacher-check/change",
    "/session/sign_in",
    "/session/sign_in_code",
    "/session/sign-in",
    "/session/sign-in-code",
    "/session",
  ].freeze

  PUBLIC_API_PATH_PREFIXES = [
    "/api/guidance",
    "/api/docs",
  ].freeze

  def self.api_request?(request)
    request.path.starts_with?("/api/")
  end

  def self.public_api_path?(request)
    PUBLIC_API_PATH_PREFIXES.any? { |prefix| request.path.starts_with?(prefix) }
  end

  def self.protected_path?(request)
    PROTECTED_ROUTES.any? { |route| request.path.starts_with?(route) }
  end

  def self.csp_report_path?(request)
    request.path == "/csp_reports"
  end

  def self.get_an_identity_webhook_path?(request)
    request.path.starts_with?("/api/v1/get_an_identity/webhook_messages")
  end

  def self.auth_token(request)
    request.get_header("HTTP_AUTHORIZATION")
  end

  # Throttle protected routes by IP (5rpm)
  throttle("protected routes (hitting external services)", limit: 10, period: 2.minutes) do |request|
    request.ip if protected_path?(request)
  end

  # Throttle /csp_reports requests by IP (5rpm)
  throttle("csp_reports req/ip", limit: 5, period: 1.minute) do |request|
    request.ip if csp_report_path?(request)
  end

  # Throttle /api/v1/get_an_identity/webhook_messages requests by IP (1000 requests per 5 minutes)
  throttle("API get an identity webhook message requests by ip", limit: 1000, period: 5.minutes) do |request|
    request.ip if get_an_identity_webhook_path?(request)
  end

  # Throttle private /api requests by auth token (1000 requests per 5 minutes)
  throttle("API requests by auth token", limit: 1000, period: 5.minutes) do |request|
    auth_token(request) if api_request?(request) && !public_api_path?(request)
  end

  # Throttle public /api requests by ip (300 requests per 5 minutes)
  throttle("public API requests by ip", limit: 300, period: 5.minutes) do |request|
    request.ip if public_api_path?(request)
  end

  # Throttle non-api requests (300 requests per 5 minutes)
  throttle("non-API requests by ip", limit: 300, period: 5.minutes) do |request|
    request.ip unless api_request?(request)
  end

  # Catch all/backstop; throttle all requests by IP (1500 requests per 5 minutes).
  # Important: this should be a higher limit than the other throttles to ensure that
  # it only comes into effect when the other throttles have been exhausted.
  throttle("catch all requests by ip", limit: 1500, period: 5.minutes, &:ip)
end

ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, request_id, payload|
  ip = payload[:request].ip
  path = payload[:request].fullpath

  Rails.logger.warn("[rack-attack] Throttled request #{request_id} from #{ip} to '#{path}'")
end
