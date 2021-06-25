# frozen_string_literal: true

# Throttle general requests by IP
class Rack::Attack
  throttle("General requests by ip", limit: 300, period: 5.minutes, &:ip)

  protected_routes = ["/registration/confirm_email", "/registration/resend_code", "/registration/qualified_teacher_check"]
  throttle("Rate limit external APIs", limit: 5, period: 20.seconds) do |request|
    request.ip if protected_routes.include?(request.path)
  end
end

ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, request_id, payload|
  ip = payload[:request].ip
  path = payload[:request].fullpath

  Rails.logger.warn("[rack-attack] Throttled request #{request_id} from #{ip} to '#{path}'")
end
