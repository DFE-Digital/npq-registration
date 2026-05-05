require "rails_helper"

RSpec.describe Crons::EnqueueTokenRefreshesJob do
  describe "#schedule" do
    it "enqueues job" do
      expect {
        described_class.schedule
      }.to have_enqueued_job
    end
  end

  describe "#perform" do
    let!(:stale_user) { create(:user, :with_token, trn: nil, token: "old", token_updated_at: 8.days.ago) }
    let!(:fresh_user) { create(:user, :with_token, trn: nil, token: "ok", token_updated_at: 1.day.ago) }
    let!(:user_without_token) { create(:user, trn: nil) }

    it "enqueues a RefreshUserTokenJob for users whose refresh token is older than 7 days" do
      expect {
        described_class.perform_now
      }.to have_enqueued_job(RefreshUserTokenJob).with(stale_user.id).exactly(:once)
    end

    it "does not enqueue jobs for users with fresh tokens or no token" do
      described_class.perform_now

      expect(RefreshUserTokenJob).not_to have_been_enqueued.with(fresh_user.id)
      expect(RefreshUserTokenJob).not_to have_been_enqueued.with(user_without_token.id)
    end
  end
end
