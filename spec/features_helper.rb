# frozen_string_literal: true

require "capybara"
require "capybara/rspec"
require "axe-rspec"
require "axe-capybara"
require "selenium-webdriver"

Capybara.register_driver :chrome_headless do |app|
  args = %w[disable-build-check disable-dev-shm-usage disable-gpu no-sandbox window-size=1400,1400 enable-features=NetworkService,NetworkServiceInProcess disable-features=VizDisplayCompositor]
  args << "headless" unless ENV["NOT_HEADLESS"]

  http_client = Selenium::WebDriver::Remote::Http::Default.new
  http_client.read_timeout = 120
  http_client.open_timeout = 120

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: Selenium::WebDriver::Options.chrome(args:),
    http_client:,
  )
end

Capybara.javascript_driver = :chrome_headless
Capybara.default_max_wait_time = 10
