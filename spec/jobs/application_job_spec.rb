require "rails_helper"

RSpec.describe ApplicationJob, type: :job do
  let :simple_job do
    Class.new(ApplicationJob) do
      def self.name
        "SimpleJob"
      end

      def perform
        user = User.first
        user.email = "#{Time.zone.now.to_i}@example.com"
        user.save!
      end
    end
  end

  describe "PaperTrail whodunnit in jobs", :versioning do
    before do
      create(:user)
      simple_job.perform_now
    end

    it "sets whodunnit to the job class name" do
      expect(PaperTrail::Version.last.whodunnit).to eq("Background job: SimpleJob")
    end
  end

  context "when a job fails" do
    before do
      stub_const failing_job.name, failing_job
      allow(Sentry).to receive(:capture_exception)
    end

    let :failing_job do
      Class.new(ApplicationJob) do
        def self.name = "FailingJob"
        def perform = raise("Job failed")
      end
    end

    let :perform_job do
      perform_enqueued_jobs do
        failing_job.perform_later
      rescue RuntimeError
        nil
      end
    end

    it "makes 18 attempts" do
      expect { perform_job }.to have_performed_job.exactly(18).times
    end

    it "reports any errors" do
      perform_job

      expect(Sentry).to have_received(:capture_exception)
                          .at_least(18) # overeports in test env for some reason
                          .times
    end
  end
end
