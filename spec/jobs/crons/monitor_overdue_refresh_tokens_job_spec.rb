require "rails_helper"

RSpec.describe Crons::MonitorOverdueRefreshTokensJob do
  describe "#schedule" do
    it "enqueues job" do
      expect {
        described_class.schedule
      }.to have_enqueued_job
    end
  end

  describe "#perform" do
    let(:overdue_age) { (OauthToken::REFRESH_LIFETIME + OauthToken::REFRESH_OVERDUE_GRACE + 1.hour).ago }
    let(:within_grace_age) { (OauthToken::REFRESH_LIFETIME + 2.hours).ago }
    let(:fresh_age) { (OauthToken::REFRESH_LIFETIME - 2.hours).ago }

    before { allow(Sentry).to receive(:capture_message) }

    context "when refresh tokens are older than the refresh point plus grace" do
      before do
        create(:user, :with_refresh_token, trn: nil, token: "overdue", token_updated_at: overdue_age)
      end

      it "reports the count of too-old tokens to Sentry as an error" do
        described_class.perform_now

        expect(Sentry).to have_received(:capture_message).with(
          "OAuth refresh tokens are not being refreshed",
          level: :error,
          extra: { overdue_count: 1 },
        )
      end
    end

    context "when all refresh tokens are within the refresh point plus grace" do
      before do
        create(:user, :with_refresh_token, trn: nil, token: "within-grace", token_updated_at: within_grace_age)
        create(:user, :with_refresh_token, trn: nil, token: "fresh", token_updated_at: fresh_age)
      end

      it "does not notify Sentry" do
        described_class.perform_now

        expect(Sentry).not_to have_received(:capture_message)
      end
    end
  end
end
