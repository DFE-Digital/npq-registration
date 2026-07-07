require "rails_helper"

RSpec.describe "Loading application seeds" do
  describe "large_seed:background" do
    subject(:run_task) { Rake::Task["large_seed:background"].invoke }

    after { Rake::Task["large_seed:background"].reenable }

    it "enqueues a SeedingJob" do
      expect { run_task }.to have_enqueued_job(SeedingJob).with(times: 2)
    end
  end

  describe "large_seed:now" do
    subject(:run_task) { Rake::Task["large_seed:now"].invoke }

    after { Rake::Task["large_seed:now"].reenable }

    it "runs the SeedingJob immediately" do
      expect(SeedingJob).to receive(:perform_now)
      run_task
    end
  end
end
