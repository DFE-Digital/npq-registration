RSpec.shared_context("with activerecord flipper") do
  before do
    config = Flipper::Configuration.new
    config.adapter { Flipper::Adapters::ActiveRecord.new }
    config.default { Flipper.new(config.adapter) }

    allow(Flipper).to receive(:instance) { config.default }
  end
end
