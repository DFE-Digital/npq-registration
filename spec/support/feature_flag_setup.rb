RSpec.configure do |config|
  config.before(:each) do
    # Set GAI integration to enabled for all users by default
    allow(Flipper).to receive(:enabled?).and_call_original
    allow(Flipper).to receive(:enabled?).with(Services::Feature::GAI_INTEGRATION_KEY, anything).and_return(true)
  end
end
