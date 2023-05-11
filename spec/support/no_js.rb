module NoJsTests
  extend ActiveSupport::Concern

  included do
    around do |example|
      Capybara.current_driver = :rack_test
      example.run
    ensure
      Capybara.current_driver = Capybara.default_driver
    end
  end

  RSpec.configure do |rspec|
    rspec.include self, :no_js
  end
end
