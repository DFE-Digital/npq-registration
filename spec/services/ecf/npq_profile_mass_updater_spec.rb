require "rails_helper"

RSpec.describe Ecf::NpqProfileMassUpdater do
  subject do
    described_class.new(applications: Application.all, &provided_proc)
  end

  let(:applications) { Application.all }
  let(:provided_proc) { proc { |_application| :arbitrary } }

  before do
    create_list(:application, 5)
  end

  it "calls ecf to update the eligible_for_funding attribute" do
    stubbed_updater = double(:stubbed_updater)
    allow(stubbed_updater).to receive(:call)
    applications.each do |application|
      expect(Ecf::NpqProfileUpdater).to receive(:new).with(application:).and_return(stubbed_updater)
      expect(provided_proc).to receive(:call).with(application)
    end

    subject.call
  end

  context "when ecf_api_disabled flag is toggled on" do
    before { Flipper.enable(Feature::ECF_API_DISABLED) }

    it "does not call ecf" do
      subject.call

      applications.each do |application|
        expect(a_request(:patch, "https://ecf-app.gov.uk/api/v1/npq-profiles/#{application.ecf_id}")).not_to have_been_made
      end
    end
  end
end
