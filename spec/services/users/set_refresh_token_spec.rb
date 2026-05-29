# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::SetRefreshToken do
  describe ".call" do
    context "when the user has no TRN and a refresh token is supplied" do
      it "creates an oauth_token record when none exists" do
        user = create(:user, trn: nil)

        freeze_time do
          expect(described_class.call(user:, refresh_token: "new-refresh-token")).to be true

          expect(user.reload.oauth_token).to have_attributes(
            token: "new-refresh-token",
            token_updated_at: Time.current,
          )
        end
      end

      it "updates the existing oauth_token record" do
        user = create(:user, :with_token, trn: nil, token: "old-token", token_updated_at: 2.days.ago)

        freeze_time do
          expect(described_class.call(user:, refresh_token: "new-refresh-token")).to be true

          expect(user.reload.oauth_token).to have_attributes(
            token: "new-refresh-token",
            token_updated_at: Time.current,
          )
        end
      end
    end

    context "when no refresh token is supplied" do
      it "is a no-op and returns false" do
        user = create(:user, trn: nil)

        expect(described_class.call(user:, refresh_token: nil)).to be false
        expect(user.reload.oauth_token).to be_nil
      end

      it "does not destroy an existing oauth_token when one is present" do
        user = create(:user, :with_token, trn: nil, token: "existing")

        expect(described_class.call(user:, refresh_token: nil)).to be false
        expect(user.reload.oauth_token).to be_present
      end
    end

    context "when the user has a TRN" do
      it "destroys an existing oauth_token and returns false" do
        user = create(:user, :with_token, trn: "1234567", token: "stale")

        expect(described_class.call(user:, refresh_token: "ignored")).to be false
        expect(user.reload.oauth_token).to be_nil
      end

      it "is a no-op and returns false when no oauth_token exists" do
        user = create(:user, trn: "1234567")

        expect(described_class.call(user:, refresh_token: "ignored")).to be false
        expect(user.reload.oauth_token).to be_nil
      end
    end
  end
end
