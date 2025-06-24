source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.read(".ruby-version").chomp

gem "activerecord-session_store"
gem "azure-blob"
gem "blueprinter"
gem "bootsnap", ">= 1.1.0", require: false
gem "canonical-rails"
gem "countries"
gem "cssbundling-rails", "~> 1.4"
gem "daemons"
gem "delayed_cron_job"
gem "delayed_job", "~> 4.1"
gem "delayed_job_active_record"
gem "delayed_job_web"
gem "devise", "~> 4.9"
gem "dfe-analytics", github: "DFE-Digital/dfe-analytics", tag: "v1.15.6"
gem "email_validator", require: "email_validator/strict"
gem "flipper", "~> 1.3"
gem "flipper-active_record", "~> 1.3"
gem "flipper-ui", "~> 1.3"
gem "google-cloud-bigquery"
gem "govuk-components", "~> 5.10"
gem "govuk_design_system_formbuilder", "~> 5.8"
gem "govuk_markdown"
gem "httparty", "~> 0.23"
gem "iconv"
gem "jsbundling-rails", "~> 1.3"
gem "mail-notify"
gem "oj"
gem "omniauth"
gem "omniauth_openid_connect"
gem "omniauth-rails_csrf_protection"
gem "pagy"
gem "paper_trail", "~> 16.0"
gem "pg", ">= 0.18", "< 2.0"
gem "pg_search"
gem "puma", "~> 6.6.0"
gem "rack-attack"
gem "rails", "~> 7.2.2"
gem "rails_semantic_logger"
gem "redis"
gem "rouge"
gem "rubyzip"
gem "secure_headers"
gem "sentry-delayed_job"
gem "sentry-rails"
gem "sentry-ruby"
gem "simpleidn", "~> 0.2.3"
gem "sprockets", "~> 4.2.2"
gem "sprockets-rails", require: "sprockets/railtie"
gem "state_machines-activerecord"
gem "strong_migrations"

gem "net-imap", "~> 0.5.9", require: false
gem "net-pop", require: false
gem "net-smtp", "~> 0.5.1", require: false

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
  gem "parallel_tests", "~> 5.2"
  gem "rspec-rails", "~> 7.1"
  gem "rspec-sonarqube-formatter", require: false
  gem "rswag-specs"
  gem "rubocop-govuk"
  gem "scss_lint-govuk"
  gem "simplecov", require: false
end

group :development do
  gem "brakeman"
  gem "i18n-debug"
  gem "listen", ">= 3.0.5", "< 3.10"
  gem "rails-erd"
  gem "web-console", ">= 3.3.0"
end

group :test do
  gem "axe-core-capybara", "~> 4.7"
  gem "axe-core-rspec", "~> 4.10"
  gem "cuprite"
  gem "rspec-default_http_header"
  gem "shoulda-matchers", "~> 6.5"
  gem "site_prism", "~> 5.1"
  gem "webmock", "~> 3.25"
end

group :development, :test, :review, :sandbox do
  gem "factory_bot_rails"
  gem "faker", "~> 3.5"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
