# frozen_string_literal: true

module BannerHelper
  def maintenance_banner_dismissed?
    cookie_value = cookies[:dismiss_maintenance_banner_until]
    return unless cookie_value

    dismissed_until = Time.zone.parse(cookie_value)
    return unless dismissed_until

    dismissed_until > Time.zone.now
  end
end
