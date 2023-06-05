# frozen_string_literal: true

# Throttle general requests by IP
class Rack::Attack
  throttle("General requests by ip", limit: 300, period: 5.minutes, &:ip)

  protected_routes = [
    "/registration/contact_details",
    "/registration/contact_details/change",
    "/registration/confirm_email",
    "/registration/confirm_email/change",
    "/registration/qualified_teacher_check",
    "/registration/qualified_teacher_check/change",
    "/session/sign_in",
    "/session/sign_in_code",
  ]
  throttle("Rate limit external APIs", limit: 5, period: 1.minute) do |request|
    request.ip if protected_routes.include?(request.path)
  end

  # Throttle /csp_reports requests by IP (5rpm)
  throttle("csp_reports req/ip", limit: 5, period: 1.minute) do |req|
    req.ip if req.path == "/csp_reports"
  end
end

ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, request_id, payload|
  ip = payload[:request].ip
  path = payload[:request].fullpath

  Rails.logger.warn("[rack-attack] Throttled request #{request_id} from #{ip} to '#{path}'")
end
