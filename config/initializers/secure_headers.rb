# frozen_string_literal: true

# need to disable Lint/PercentStringArray here, because CSP keywords need to be single-quoted
# rubocop:disable Lint/PercentStringArray
SecureHeaders::Configuration.default do |config|
  config.x_frame_options = "DENY"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "0"
  config.x_download_options = "noopen"
  config.x_permitted_cross_domain_policies = "none"
  config.referrer_policy = %w[origin-when-cross-origin strict-origin-when-cross-origin]

  google_analytics = %w[*.google-analytics.com *.analytics.google.com *.googletagmanager.com tagmanager.google.com *.googleusercontent.com *.gstatic.com]
  tracking_pixels = %w[www.facebook.com px.ads.linkedin.com]
  sentry = []

  if ENV["SENTRY_REPORT_URI"]
    sentry_report_uri = [ENV["SENTRY_REPORT_URI"]]
    sentry = [sentry_report_uri.host]
  end

  config.csp = SecureHeaders::OPT_OUT

  config.csp_report_only = {
    default_src: %w['none'],
    base_uri: %w['self'],
    upgrade_insecure_requests: true,
    child_src: %w['self'],
    connect_src: %w['self'] + google_analytics + sentry,
    font_src: %w['self' *.gov.uk fonts.gstatic.com],
    form_action: %w['self'],
    frame_ancestors: %w['self'],
    frame_src: %w['self'] + google_analytics,
    img_src: %w['self' data: *.gov.uk] + google_analytics + tracking_pixels,
    manifest_src: %w['self'],
    media_src: %w['self'],
    script_src: %w['self' *.gov.uk https://cdn.jsdelivr.net/npm/chart.js] + google_analytics,
    style_src: %w['self' 'unsafe-inline' *.gov.uk fonts.googleapis.com] + google_analytics, # unsafe-inline is needed for Flipper:UI
    worker_src: %w['self'],
    report_uri: sentry_report_uri,
  }
end
# rubocop:enable Lint/PercentStringArray
