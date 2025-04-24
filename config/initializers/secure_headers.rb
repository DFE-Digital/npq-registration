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
  flippercloud = %w[www.flippercloud.io]
  identity_domain = [ENV["TRA_OIDC_DOMAIN"]]
  sentry = %w[*.sentry-cdn.com *.ingest.us.sentry.io]

  if ENV["SENTRY_CSP_REPORT_URI"]
    sentry_report_uri = ENV["SENTRY_CSP_REPORT_URI"]
    sentry += [URI(sentry_report_uri).host]
  end

  flipper_ui_hashes = %w[
    'sha256-NNzAJMHPK9KuPslppuoTz2azqZcpUO0IJZosehbmhHA='
    'sha256-zuOhDbTpAZjaeemuptCNLaf/7IaV06c8De4EMGOhtzM='
  ]

  config.csp = SecureHeaders::OPT_OUT

  config.csp_report_only = {
    default_src: %w['none'],
    base_uri: %w['self'],
    upgrade_insecure_requests: true,
    child_src: %w['self'],
    connect_src: %w['self'] + google_analytics + flippercloud + sentry,
    font_src: %w['self' *.gov.uk fonts.gstatic.com],
    form_action: %w['self'] + identity_domain, # needed because the POST to /users/auth/tra_openid_connect' redirects to the identity domain
    frame_ancestors: %w['self'],
    frame_src: %w['self'] + google_analytics,
    img_src: %w['self' data: *.gov.uk] + google_analytics + tracking_pixels,
    manifest_src: %w['self'],
    media_src: %w['self'],
    script_src: %w['self' *.gov.uk https://cdn.jsdelivr.net/npm/chart.js] + google_analytics + sentry,
    style_src: %w['self' *.gov.uk fonts.googleapis.com] + google_analytics + %w['unsafe-hashes'] + flipper_ui_hashes,
    worker_src: %w['self'],
    report_uri: [sentry_report_uri],
  }
end
# rubocop:enable Lint/PercentStringArray
