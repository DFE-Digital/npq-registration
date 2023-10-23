require "rails_helper"

RSpec.describe ApplicationSynchronizationJob, type: :job do
  describe "#perform_later" do
    it "enqueues job" do
      expect {
        described_class.perform_later
      }.to have_enqueued_job
    end
  end

  describe "#perform" do
    it "calls the EcfApplicationSynchronization" do
      mock = instance_double("ECF::EcfApplicationSynchronization", call: nil)

      allow(ECF::EcfApplicationSynchronization).to receive(:new).and_return(mock)
      described_class.perform_now
      expect(mock).to have_received(:call)
    end
  end
end
