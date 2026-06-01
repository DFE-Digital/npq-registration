require "rails_helper"

RSpec.describe RefreshUserTokenJob do
  let(:user) { create(:user, :with_refresh_token, trn: nil, token: "old-token", token_updated_at: 8.days.ago) }

  describe "#perform" do
    context "when the user has a refresh token and no TRN" do
      before do
        allow(TeacherAuth::RefreshAccessToken).to receive(:call).with(refresh_token: "old-token").and_return("new-token")
      end

      it "updates the refresh token and timestamp" do
        freeze_time do
          described_class.new.perform(user.id)

          user.reload
          expect(user.refresh_token.token).to eq("new-token")
          expect(user.refresh_token.token_updated_at).to eq(Time.current)
        end
      end
    end

    context "when the user has been deleted between enqueue and run" do
      it "is a no-op" do
        expect {
          described_class.new.perform(user.id + 999)
        }.not_to raise_error
      end
    end

    context "when the user has acquired a TRN since enqueue" do
      before { user.update!(trn: "1234567") }

      it "does not call the refresh service" do
        expect(TeacherAuth::RefreshAccessToken).not_to receive(:call)
        described_class.new.perform(user.id)
      end
    end

    context "when the refresh token has been cleared since enqueue" do
      before { user.refresh_token.destroy! }

      it "does not call the refresh service" do
        expect(TeacherAuth::RefreshAccessToken).not_to receive(:call)
        described_class.new.perform(user.id)
      end
    end

    context "when the refresh service raises" do
      before do
        allow(TeacherAuth::RefreshAccessToken).to receive(:call).and_raise(StandardError, "boom")
      end

      it "reports to Sentry and does not re-raise" do
        expect(Sentry).to receive(:capture_exception).with(instance_of(StandardError), any_args).at_least(:once)
        expect {
          described_class.perform_now(user.id)
        }.not_to raise_error
      end
    end
  end
end
