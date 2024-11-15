require "rails_helper"

RSpec.describe Crons::CheckAnalyticsEntity, type: :job do
  before do
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  describe "#perform" do
    context "when there are no more than batch_size records" do
      it "enqueues the send job for each record" do
        described_class.perform_now

        expect(DfE::Analytics::EntityTableCheckJob).to(have_been_enqueued.exactly(:once).on_queue("dfe_analytics"))
      end
    end
  end
end
