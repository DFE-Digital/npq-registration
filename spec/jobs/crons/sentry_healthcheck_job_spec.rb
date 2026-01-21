require "rails_helper"

RSpec.describe Crons::SentryHealthcheckJob, type: :job do
  before do
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  describe "#perform" do
    context "when there are no more than batch_size records" do
      it "enqueues the job" do
        described_class.perform_now

        expect { described_class.perform_later }.to have_enqueued_job(described_class).exactly(:once).on_queue("default")
      end

      it "sends a Sentry check in" do
        expect(Sentry).to receive(:capture_check_in).with("sentry-healthcheck", :in_progress, any_args)
        expect(Sentry).to receive(:capture_check_in).with("sentry-healthcheck", :ok, any_args)

        described_class.perform_now
      end
    end
  end
end
