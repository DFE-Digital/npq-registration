require "rails_helper"

RSpec.describe Users::BlankEmailForReuse do
  subject { described_class.new(user:) }

  let(:user) { create(:user, :with_get_an_identity_id, email: "reused@example.com") }

  before { allow(Sentry).to receive(:capture_message) }

  describe "#call" do
    it "moves the email to archived_email and sets email to nil" do
      freeze_time do
        subject.call

        user.reload
        expect(user.email).to be_nil
        expect(user.archived_email).to eq("reused@example.com")
        expect(user.archived_at).to eq(Time.zone.now)
        expect(user).to be_archived
      end
    end

    it "clears uid and provider" do
      subject.call

      user.reload
      expect(user.uid).to be_nil
      expect(user.provider).to be_nil
    end

    it "does not touch the user's applications" do
      application = create(:application, user:)

      subject.call

      expect(application.reload.user).to eq(user)
    end

    it "sends a Sentry message with the user's ecf_id" do
      subject.call

      expect(Sentry).to have_received(:capture_message).with(
        "Blanked email on the user due to reuse when used by a later participant",
        hash_including(level: :info, extra: { ecf_id: user.ecf_id }),
      )
    end
  end
end
