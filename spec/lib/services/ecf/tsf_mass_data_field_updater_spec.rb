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
    stubbed_updater = double(:stubbed_updater)
    allow(stubbed_updater).to receive(:tsf_data_field_update)
    applications.each do |application|
      expect(Ecf::NpqProfileUpdater).to receive(:new).with(application:).and_return(stubbed_updater)
      expect(provided_proc).to receive(:call).with(application)
    end

    subject.call
  end
end
