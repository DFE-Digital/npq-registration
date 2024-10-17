require "active_support/core_ext/integer/time"

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  config.after_initialize do
    Bullet.enable                       = true
    Bullet.bullet_logger                = true
    Bullet.raise                        = true # Raise an error if n+1 query occurs
    Bullet.unused_eager_loading_enable  = false # Disabled due to the way our queries are structured
    Bullet.stacktrace_excludes          = [
      "app/controllers/api", # Ignore as request spec factories cause false positives (excluding controllers as we use shared examples so can't target spec/requests/api here), see: https://github.com/flyerhzm/bullet/issues/435
      "spec/features/admin", # Ignore until they are fixed
      "npq_separation/admin", # Ignore until they are fixed
    ]
  end

  # Settings specified here will take precedence over those in config/application.rb.

  config.cache_classes = false

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.hour.to_i}",
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = :none

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raises error for missing translations.
  config.i18n.raise_on_missing_translations = true

  config.active_job.queue_adapter = :test

  config.session_store :active_record_store, key: "_npq_registration_session", secure: false, expire_after: 2.weeks

  # Enable/disable aspects of the NPQ separation
  config.npq_separation = {
    admin_portal_enabled: true,
    api_enabled: true,
    migration_enabled: true,
    ecf_api_disabled: false,
    parity_check: {
      enabled: true,
      npq_url: "http://ecf.example.com",
      ecf_url: "http://npq.example.com",
    },
  }

  config.dotenv.autorestore = false if config.respond_to?(:dotenv)
end
