# This file is copied to spec/ when you run 'rails generate rspec:install'
require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
# Add additional requires below this line. Rails is not loaded until this point!

require "site_prism"
Dir[Rails.root.join("spec/page_objects/**/*_section.rb")].sort.each { |f| require f }
Dir[Rails.root.join("spec/page_objects/**/*_page.rb")].sort.each { |f| require f }

require "axe-rspec"
require "axe-capybara"

require "active_support/core_ext/date/conversions"
require "active_support/core_ext/time/conversions"

require "view_component/test_helpers"
require "view_component/system_test_helpers"
require "capybara/rspec"

Capybara.register_driver :headless_chrome do |app|
  version = Capybara::Selenium::Driver.load_selenium
  options_key = Capybara::Selenium::Driver::CAPS_VERSION.satisfied_by?(version) ? :capabilities : :options
  browser_options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    opts.add_argument("--headless")
    opts.add_argument("--disable-gpu")
    opts.add_argument("--window-size=1920,1080")
    # Workaround https://bugs.chromium.org/p/chromedriver/issues/detail?id=2650&q=load&sort=-id&colspec=ID%20Status%20Pri%20Owner%20Summary
    opts.add_argument("--disable-site-isolation-trials")
  end

  Capybara::Selenium::Driver.new(app, **{ :browser => :chrome, options_key => browser_options })
end

Capybara.default_driver = :headless_chrome
Capybara.javascript_driver = :headless_chrome

require "capybara-screenshot/rspec"

Capybara::Screenshot.register_driver(:headless_chrome) do |driver, path|
  driver.browser.save_screenshot path
end

AxeCapybara.configure(:headless_chrome) do
  # see below for a full list of configuration
  # c.jslib_path = "next-version/axe.js"
end

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

Capybara.server = :puma, { Silent: true }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include ActiveSupport::Testing::TimeHelpers
  config.include ActiveJob::TestHelper, type: :feature
  config.include ViewComponent::TestHelpers, type: :component
  config.include ViewComponent::SystemTestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component
  config.include Helpers::APIHelpers, type: :request

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join("spec/fixtures"),
  ]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.before(:suite) do
    Course::IDENTIFIERS.each do |identifier|
      FactoryBot.create(identifier)
    end
  end

  config.before do
    Flipper.enable(Feature::REGISTRATION_OPEN)
  end

  config.before(:each, exceptions_app: true) do
    # Make the app behave how it does in non dev/test environments and use the
    # ErrorsController via config.exceptions_app = routes in config/application.rb
    method = Rails.application.method(:env_config)
    allow(Rails.application).to receive(:env_config).with(no_args) do
      method.call.merge(
        "action_dispatch.show_exceptions" => :all,
        "action_dispatch.show_detailed_exceptions" => false,
        "consider_all_requests_local" => false,
      )
    end
  end

  config.include Helpers::JourneyHelper, type: :feature
  config.before(:each, type: :feature) do
    stub_env_variables_for_gai
  end

  config.around(:each, in_memory_rails_cache: true) do |example|
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
    Rails.cache.clear
  end

  config.around(:each, rack_test_driver: true) do |example|
    Capybara.current_driver = :rack_test
    example.run
    Capybara.current_driver = Capybara.default_driver
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
