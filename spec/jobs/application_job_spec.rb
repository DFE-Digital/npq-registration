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
      expect(PaperTrail::Version.last.whodunnit).to eq("SimpleJob")
    end
  end
end
