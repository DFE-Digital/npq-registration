RSpec.shared_context("retrieve latest application data") do
  before do
    # Make sure all the tests are checking this data
    expect(self).to receive(:retrieve_latest_application_user_data).and_call_original
    expect(self).to receive(:retrieve_latest_application_data).and_call_original
  end
end
