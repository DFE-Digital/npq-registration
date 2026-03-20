source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.read(".ruby-version").chomp

gem "activerecord-session_store"
gem "azure-blob"
gem "blueprinter"
gem "bootsnap", ">= 1.1.0", require: false
gem "canonical-rails"
gem "connection_pool", "~> 2.5" # v3 swaps to kwargs, we'll upgrade as part of Rails 8.1
gem "countries"
gem "cssbundling-rails", "~> 1.4"
gem "daemons"
gem "delayed_cron_job"
gem "delayed_job", "~> 4.1"
gem "delayed_job_active_record"
gem "devise", "~> 5.0"
gem "dfe-analytics", github: "DFE-Digital/dfe-analytics", tag: "v1.15.6"
gem "email_validator", require: "email_validator/strict"
gem "faraday-retry"
gem "flipper"
gem "flipper-active_record"
gem "google-cloud-bigquery"
gem "govuk-components", "~> 5.11"
gem "govuk_design_system_formbuilder", "~> 5.8"
gem "govuk_markdown"
gem "httparty", "~> 0.24"
gem "jsbundling-rails", "~> 1.3"
gem "linzer"
gem "mail-notify"
gem "method_source"
gem "oj"
gem "omniauth"
gem "omniauth_openid_connect"
gem "omniauth-rails_csrf_protection"
gem "pagy"
gem "paper_trail"
gem "pg", ">= 0.18", "< 2.0"
gem "pg_search"
gem "puma", "~> 7.1"
gem "rack-attack"
gem "rails", "~> 8.0.4"
gem "rails_semantic_logger"
gem "redis"
gem "rouge"
gem "secure_headers"
gem "sentry-delayed_job"
gem "sentry-rails"
gem "sentry-ruby"
gem "simpleidn"
gem "skylight", "~> 7.0"
gem "sprockets", "~> 4.2.2"
gem "sprockets-rails", require: "sprockets/railtie"
gem "state_machines-activerecord"
gem "strong_migrations"
gem "with_advisory_lock"

group :development, :test, :review do
  gem "bullet"
end

group :development, :test do
  gem "amazing_print"
  gem "capybara"
  gem "capybara-screenshot"
  gem "debug"
  gem "dotenv-rails"
  gem "knapsack"
  gem "parallel_tests"
  gem "rspec-rails"
  gem "rspec-sonarqube-formatter", require: false
  gem "rswag-specs"
  gem "rubocop-govuk"
  gem "scss_lint-govuk"
  gem "simplecov", require: false
end

group :development do
  gem "brakeman"
  gem "foreman"
  gem "i18n-debug"
  gem "listen", ">= 3.0.5"
  gem "rails-erd"
  gem "web-console", ">= 3.3.0"
end

group :test do
  gem "axe-core-capybara", "~> 4.7"
  gem "axe-core-rspec", "~> 4.11"
  gem "cuprite"
  gem "rspec-default_http_header"
  gem "shoulda-matchers"
  gem "site_prism", "~> 5.1"
  gem "webmock", "~> 3.26"
end

group :development, :test, :review, :sandbox do
  gem "factory_bot_rails"
  gem "faker"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
