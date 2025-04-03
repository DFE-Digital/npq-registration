require "rails_helper"

RSpec.describe Cohorts::CopyDeliveryPartnersJob do
  let(:cohort) { create(:cohort) }
  let(:service_instance) { instance_double(Cohorts::CopyDeliveryPartners, copy: nil) }

  before do
    allow(Cohorts::CopyDeliveryPartners).to receive(:new).with(cohort).and_return(service_instance)
  end

  it "calls the service" do
    described_class.perform_now(cohort.id)
    expect(service_instance).to have_received(:copy)
  end
end
