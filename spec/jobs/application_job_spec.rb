require "rails_helper"

class SimpleJob < ApplicationJob
  def perform
    user = User.first
    user.email = "#{Time.zone.now.to_i}@example.com"
    user.save!
  end
end

RSpec.describe ApplicationJob, type: :job do
  describe "PaperTrail whodunnit in jobs", :versioning do
    before do
      create(:user)
      SimpleJob.perform_now
    end

    it "sets whodunnit to the job class name" do
      expect(PaperTrail::Version.last.whodunnit).to eq("SimpleJob")
    end
  end
end
