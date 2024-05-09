source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.read(".ruby-version").chomp

gem "activerecord-session_store"
gem "blueprinter"
gem "bootsnap", ">= 1.1.0", require: false
gem "canonical-rails"
gem "daemons"
gem "delayed_cron_job"
gem "delayed_job", "~> 4.1"
gem "delayed_job_active_record"
gem "delayed_job_web"
gem "devise", "~> 4.9"
gem "email_validator", require: "email_validator/strict"
gem "flipper", "~> 1.2.2"
gem "flipper-active_record", "~> 1.2.2"
gem "flipper-ui", "~> 1.2.2"
gem "google-cloud-bigquery"
gem "govuk-components", "~> 5.3.2"
gem "govuk_design_system_formbuilder", "~> 5.3.3"
gem "govuk_markdown"
gem "httparty", "~> 0.22"
gem "iconv"
gem "json_api_client", ">= 1.21.1"
gem "lograge", ">= 0.11.2"
gem "logstash-event"
gem "mail-notify"
gem "oj"
gem "omniauth"
gem "omniauth-oauth2"
gem "omniauth-rails_csrf_protection"
gem "pagy"
gem "paper_trail", "~> 15.1"
gem "pg", ">= 0.18", "< 2.0"
gem "pg_search"
gem "puma", "~> 6.4.2"
gem "rack-attack"
gem "rails", "~> 7"
gem "redis"
gem "rouge"
gem "rubyzip"
gem "scenic"
gem "secure_headers"
gem "sentry-delayed_job"
gem "sentry-rails"
gem "sentry-ruby"
gem "state_machines-activerecord"
gem "stimulus-rails"
gem "webpacker"
gem "whenever"

gem "net-imap", "~> 0.4.10", require: false
gem "net-pop", require: false
gem "net-smtp", "~> 0.5.0", require: false

group :development, :test do
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "capybara"
  gem "capybara-screenshot"
  gem "dotenv-rails"
  gem "pry-byebug"
  gem "pry-rails"
  gem "rspec-rails", "~> 6.1.2"
  gem "rswag-specs"
  gem "rubocop-govuk"
  gem "scss_lint-govuk"
end

group :development do
  gem "brakeman"
  gem "i18n-debug"
  gem "listen", ">= 3.0.5", "< 3.10"
  gem "web-console", ">= 3.3.0"
end

group :test do
  gem "axe-core-capybara", "~> 4.6"
  gem "axe-core-rspec", "~> 4.9"
  gem "shoulda-matchers", "~> 6.2"
  gem "simplecov", require: false
  gem "site_prism", "~> 5.0"
  gem "webdrivers"
  gem "webmock", "~> 3.23"
  gem "with_model", "~> 2.1", ">= 2.1.7"
end

group :development, :test, :review do
  gem "factory_bot_rails"
  gem "faker", "~> 3.3"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
