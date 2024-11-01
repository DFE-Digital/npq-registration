require "rails_helper"

RSpec.describe ParityCheckJob do
  let(:instance) { described_class.new }

  describe "#perform" do
    subject(:perform_parity_check) { instance.perform }

    let(:parity_check_double) { instance_double(Migration::ParityCheck, run!: nil) }

    before { allow(Migration::ParityCheck).to receive(:new).and_return(parity_check_double) }

    it "triggers a parity check" do
      perform_parity_check
      expect(parity_check_double).to have_received(:run!).once
    end
  end

  describe "#perform_later" do
    it "schedules job in migration queue" do
      expect {
        described_class.perform_later
      }.to have_enqueued_job(described_class).on_queue("high_priority")
    end
  end
end
