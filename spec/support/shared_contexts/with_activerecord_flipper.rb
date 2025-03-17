RSpec.shared_context("with activerecord flipper") do
  around do |example|
    Flipper.configure do |config|
      config.adapter { Flipper::Adapters::ActiveRecord.new }
      config.default { Flipper.new(config.adapter) }
    end

    example.run

    Flipper::TestHelp.flipper_configure
  end
end
