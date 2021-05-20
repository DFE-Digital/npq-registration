source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.read(".ruby-version").chomp

gem "bootsnap", ">= 1.1.0", require: false
gem "canonical-rails"
gem "devise"
gem "email_validator", require: "email_validator/strict"
gem "foreman"
gem "govuk-components"
gem "govuk_design_system_formbuilder"
gem "mail-notify"
gem "pg", ">= 0.18", "< 2.0"
gem "puma", "~> 5.3"
gem "rails", "~> 6.1.3"
gem "webpacker"

group :development, :test do
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "capybara", "~> 3.35"
  gem "dotenv-rails"
  gem "pry-byebug"
  gem "rspec-rails", "~> 5.0.1"
  gem "rubocop-govuk"
  gem "scss_lint-govuk"
end

group :development do
  gem "i18n-debug"
  gem "listen", ">= 3.0.5", "< 3.6"
  gem "web-console", ">= 3.3.0"
end

group :test do
  gem "shoulda-matchers", "~> 4.0"
  gem "simplecov", require: false
  gem "webdrivers", "~> 4.6"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
