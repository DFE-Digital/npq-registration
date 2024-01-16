source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.read(".ruby-version").chomp

gem "activerecord-session_store"
gem "bootsnap", ">= 1.1.0", require: false
gem "canonical-rails"
gem "daemons"
gem "delayed_cron_job"
gem "delayed_job", "~> 4.1"
gem "delayed_job_active_record"
gem "delayed_job_web"
gem "devise", "~> 4.9"
gem "email_validator", require: "email_validator/strict"
gem "flipper", "~> 1.0.0"
gem "flipper-active_record", "~> 1.0.0"
gem "flipper-ui", "~> 1.0.0"
gem "google-cloud-bigquery"
gem "govuk-components", "~> 4.1.2"
gem "govuk_design_system_formbuilder", "~> 4.1.1"
gem "httparty", "~> 0.21"
gem "iconv"
gem "jbuilder"
gem "json_api_client", ">= 1.21.1"
gem "lograge", ">= 0.11.2"
gem "logstash-event"
gem "mail-notify"
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
gem "rubyzip"
gem "scenic", "~> 1.7"
gem "secure_headers"
gem "sentry-delayed_job"
gem "sentry-rails"
gem "sentry-ruby"
gem "stimulus-rails"
gem "webpacker"
gem "whenever"

gem "net-imap", "~> 0.4.9", require: false
gem "net-pop", require: false
gem "net-smtp", "~> 0.4.0", require: false

group :development, :test do
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "capybara"
  gem "capybara-screenshot"
  gem "dotenv-rails"
  gem "parallel_tests"
  gem "pry-byebug"
  gem "pry-rails"
  gem "rspec-rails", "~> 6.1.0"
  gem "rubocop-govuk"
  gem "scss_lint-govuk"
end

group :development do
  gem "brakeman"
  gem "i18n-debug"
  gem "listen", ">= 3.0.5", "< 3.9"
  gem "web-console", ">= 3.3.0"
end

group :test do
  gem "axe-core-capybara", "~> 4.6"
  gem "axe-core-rspec", "~> 4.8"
  gem "factory_bot_rails"
  gem "shoulda-matchers", "~> 5.3"
  gem "simplecov", require: false
  gem "site_prism", "~> 4.0", ">= 4.0.3"
  gem "webdrivers"
  gem "webmock", "~> 3.19", ">= 3.19.1"
  gem "with_model", "~> 2.1", ">= 2.1.7"
end

group :development, :test, :review do
  gem "faker", "~> 3.2"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
