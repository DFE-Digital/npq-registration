RSpec.shared_context("use rack_test driver") do
  around do |example|
    Capybara.current_driver = :rack_test
    example.run
    Capybara.current_driver = Capybara.default_driver
  end
end
