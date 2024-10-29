# frozen_string_literal: true

# Disable in migration environment
Rack::Attack.enabled = !Rails.env.migration?

# Throttle general requests by IP
class Rack::Attack
  PROTECTED_ROUTES = [
    "/registration/qualified_teacher_check",
    "/registration/qualified_teacher_check/change",
    "/session/sign_in",
    "/session/sign_in_code",
  ].freeze

  PUBLIC_API_PATH_PREFIXES = [
    "/api/guidance",
    "/api/docs",
  ].freeze

  # Throttle protected routes by IP (5rpm)
  throttle("protected routes (hitting external services)", limit: 5, period: 1.minute) do |request|
    request.ip if PROTECTED_ROUTES.include?(request.path)
  end

  # Throttle /csp_reports requests by IP (5rpm)
  throttle("csp_reports req/ip", limit: 5, period: 1.minute) do |request|
    request.ip if request.path == "/csp_reports"
  end

  # Throttle /api/v1/get_an_identity/webhook_messages requests by IP (1000 requests per 5 minutes)
  throttle("API get an identity webhook message requests by ip", limit: 1000, period: 5.minutes) do |request|
    request.ip if request.path.starts_with?("/api/v1/get_an_identity/webhook_messages")
  end

  # Throttle /api requests by auth token (1000 requests per 5 minutes)
  throttle("API requests by auth token", limit: 1000, period: 5.minutes) do |request|
    public_api_path = PUBLIC_API_PATH_PREFIXES.any? { |prefix| request.path.starts_with?(prefix) }

    if request.path.starts_with?("/api/") && !public_api_path
      request.get_header("HTTP_AUTHORIZATION")
    end
  end

  # Throttle all requests by IP (300 requests per 5 minutes)
  throttle("general requests by ip", limit: 300, period: 5.minutes, &:ip)
end

ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, request_id, payload|
  ip = payload[:request].ip
  path = payload[:request].fullpath

  Rails.logger.warn("[rack-attack] Throttled request #{request_id} from #{ip} to '#{path}'")
end
