source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.read(".ruby-version").chomp

gem "activerecord-session_store"
gem "bootsnap", ">= 1.1.0", require: false
gem "canonical-rails"
gem "delayed_job_active_record"
gem "email_validator", require: "email_validator/strict"
gem "flipper", "~> 0.25.2"
gem "flipper-active_record", "~> 0.25.2"
gem "flipper-ui", "~> 0.25.4"
gem "govuk-components"
gem "govuk_design_system_formbuilder"
gem "iconv"
gem "jbuilder"
gem "json_api_client"
gem "lograge", ">= 0.11.2"
gem "logstash-event"
gem "mail-notify"
gem "pagy"
gem "pg", ">= 0.18", "< 2.0"
gem "pg_search"
gem "puma", "~> 5.6"
gem "rack-attack"
gem "rails", "~> 6.1.7"
gem "secure_headers"
gem "sentry-delayed_job"
gem "sentry-rails"
gem "sentry-ruby"
gem "webpacker"

gem "net-imap", require: false
gem "net-pop", require: false
gem "net-smtp", require: false

group :development, :test do
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "capybara"
  gem "dotenv-rails"
  gem "pry-byebug"
  gem "rspec-rails", "~> 6.0.1"
  gem "rubocop-govuk"
  gem "scss_lint-govuk"
end

group :development do
  gem "brakeman"
  gem "i18n-debug"
  gem "listen", ">= 3.0.5", "< 3.8"
  gem "web-console", ">= 3.3.0"
end

group :test do
  gem "factory_bot_rails"
  gem "shoulda-matchers", "~> 5.2"
  gem "simplecov", require: false
  gem "site_prism"
  gem "webdrivers"
  gem "webmock"

  gem "axe-core-capybara"
  gem "axe-core-rspec"

  gem "with_model"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
