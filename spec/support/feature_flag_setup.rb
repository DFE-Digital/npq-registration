RSpec.configure do |config|
  config.before do
    allow(Flipper).to receive(:enabled?).and_call_original
    # allow(Flipper).to receive(:enabled?).with(Services::Feature::FEATURE_FLAG_NAME, anything).and_return(true)
  end
end
