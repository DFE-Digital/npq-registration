require "rails_helper"

RSpec.describe Crons::SweepStaleSessionsJob do
  describe "#schedule" do
    it "enqueues job" do
      expect {
        described_class.schedule
      }.to have_enqueued_job
    end
  end

  describe "#perform" do
    it "deletes stale sessions" do
      ActiveRecord::SessionStore::Session.create!(data: "world", session_id: "1", updated_at: 16.days.ago)

      expect {
        described_class.perform_now
      }.to change(ActiveRecord::SessionStore::Session, :count).by(-1)
    end

    it "does not delete active sessions" do
      ActiveRecord::SessionStore::Session.create!(data: "world", session_id: "1")

      expect {
        described_class.perform_now
      }.not_to change(ActiveRecord::SessionStore::Session, :count)
    end
  end
end
