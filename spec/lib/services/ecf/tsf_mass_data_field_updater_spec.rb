require "rails_helper"

RSpec.describe Ecf::TsfMassDataFieldUpdater do
  subject do
    described_class.new(applications: Application.all, &provided_proc)
  end

  let(:applications) { Application.all }
  let(:provided_proc) { proc { |_application| :arbitrary } }

  before do
    create_list(:application, 5)
  end

  it "calls ecf to update the eligible_for_funding attribute" do
    stubbed_updater = instance_double(Ecf::NpqProfileUpdater)
    allow(stubbed_updater).to receive(:tsf_data_field_update)
    applications.each do |application|
      allow(Ecf::NpqProfileUpdater).to receive(:new).with(application:).and_return(stubbed_updater)
      allow(provided_proc).to receive(:call).with(application)
    end

    expect(subject.call).to be_truthy
  end

  context "when ecf_api_disabled flag is toggled on" do
    before { allow(Rails.application.config).to receive(:npq_separation).and_return({ ecf_api_disabled: true }) }

    it "returns nil" do
      expect(subject.call).to be_nil
    end
  end
end
