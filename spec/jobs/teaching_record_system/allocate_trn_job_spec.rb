require "rails_helper"

RSpec.describe TeachingRecordSystem::AllocateTrnJob, type: :job do
  subject(:perform_job) { described_class.perform_now(user_id:) }

  before do
    allow(TeachingRecordSystem::RefreshTokens)
      .to receive(:refresh!).and_return %w[NEWACCESS NEWREFRESH]

    allow(TeachingRecordSystem::ActivateTrnRequest)
      .to receive(:activate!).and_return allocated_trn

    allow(Sentry).to receive(:capture_exception)
  end

  let(:user_id) { user.id }
  let(:allocated_trn) { nil }
  let(:trn) { nil }

  let :user do
    create(:user, trn:, trn_verified: !!trn, trn_auto_verified: !!trn) do |user|
      user.oauth_tokens.create(token: "OLDREFRESH", last_updated_token_at: 5.minutes.ago)
    end
  end

  describe "#perform" do
    context "with unknown user" do
      let(:user_id) { nil }

      it "throws a RecordNotFound exception" do
        expect { perform_job }
          .to raise_exception(ActiveRecord::RecordNotFound)
          .and not_change(user.oauth_tokens.first, :token)
      end
    end

    context "with user who already has TRN allocated" do
      let(:trn) { "4536243" }

      it "removes the refresh token but does not call the APIs" do
        expect { perform_job }
          .to change(user.oauth_tokens, :count).from(1).to(0)
          .and not_change(user.reload, :trn)

        expect(TeachingRecordSystem::RefreshTokens).not_to have_received(:refresh!)
        expect(TeachingRecordSystem::ActivateTrnRequest).not_to have_received(:activate!)
      end
    end

    context "with user without TRN" do
      context "when activate API does return a TRN" do
        let(:allocated_trn) { "7349349" }

        it "updates user with TRN and removes the refresh token" do
          expect { perform_job }
            .to change { user.reload.trn }.from(nil).to(allocated_trn)
            .and change(user.oauth_tokens, :count).from(1).to(0)
        end
      end

      context "when activate API does not return a TRN" do
        it "does not change TRN but removes the refresh token now activation is triggered" do
          expect { perform_job }
            .to not_change { user.reload.trn }
            .and change(user.oauth_tokens, :count).from(1).to(0)
        end
      end
    end

    context "when refresh API errors" do
      before do
        allow(TeachingRecordSystem::RefreshTokens)
          .to receive(:refresh!).and_raise(Faraday::ForbiddenError)
      end

      it "notifies Sentry and does not attempt the Activate API" do
        expect { perform_job }
          .to raise_exception(Faraday::ForbiddenError)
          .and not_change(user.reload, :trn)
          .and not_change(user.oauth_tokens.first, :token)

        expect(TeachingRecordSystem::ActivateTrnRequest).not_to have_received(:activate!)
        expect(Sentry).to have_received(:capture_exception).with(Faraday::ForbiddenError)
      end
    end

    context "when activate API errors" do
      before do
        allow(TeachingRecordSystem::ActivateTrnRequest)
          .to receive(:activate!).and_raise(Faraday::ForbiddenError)
      end

      it "notifies Sentry and allows the job to retry" do
        expect { perform_job }
          .to raise_exception(Faraday::ForbiddenError)
          .and not_change(user.reload, :trn)
          .and not_change(user.oauth_tokens, :count)
          .and change { user.oauth_tokens.first.reload.token }
                      .from("OLDREFRESH")
                      .to("NEWREFRESH")

        expect(Sentry).to have_received(:capture_exception).with(Faraday::ForbiddenError)
      end
    end
  end
end
