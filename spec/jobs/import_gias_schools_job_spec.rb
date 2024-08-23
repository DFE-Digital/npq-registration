require "rails_helper"

RSpec.describe ImportGiasSchoolsJob, type: :job do
  describe "#perform_later" do
    it "enqueues job" do
      expect {
        described_class.perform_later
      }.to have_enqueued_job
    end
  end

  describe "#perform_now" do
    it "calls ImportGiasSchools#call" do
      mock = instance_double(ImportGiasSchools, call: nil)

      allow(ImportGiasSchools).to receive(:new).and_return(mock)
      described_class.perform_now
      expect(mock).to have_received(:call)
    end
  end
end
