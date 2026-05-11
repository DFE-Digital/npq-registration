require "rails_helper"

RSpec.describe Users::Archiver do
  let(:user) { create(:user, :with_get_an_identity_id, email: "test1@example.com") }
  let(:archive_time) { 2.days.ago }

  subject { described_class.new(user:) }

  describe ".archive!" do
    it "archives user" do
      expect(user).not_to be_archived

      travel_to archive_time do
        subject.archive!
      end

      expect(user.archived_email).to eq("test1@example.com")
      expect(user.email).to eq("archived-test1@example.com")
      expect(user.uid).to be_nil
      expect(user.provider).to be_nil
      expect(user.archived_at.to_s).to eq(archive_time.to_s)
      expect(user).to be_archived
    end

    context "when already archived" do
      let(:user) { create(:user, :archived) }

      it "raises error" do
        expect(user).to be_archived

        expect {
          subject.archive!
        }.to raise_error ArgumentError, "User already archived"
      end
    end

    context "when blank_email: true" do
      it "archives user with nil email" do
        travel_to archive_time do
          subject.archive!(blank_email: true)
        end

        expect(user.archived_email).to eq("test1@example.com")
        expect(user.email).to be_nil
        expect(user.uid).to be_nil
        expect(user.provider).to be_nil
        expect(user.archived_at.to_s).to eq(archive_time.to_s)
        expect(user).to be_archived
      end

      it "sends a Sentry message with the user's ecf_id" do
        allow(Sentry).to receive(:capture_message)

        subject.archive!(blank_email: true)

        expect(Sentry).to have_received(:capture_message).with(
          "Blanked email on the user due to reuse when used by a later participant",
          hash_including(level: :info, extra: { ecf_id: user.ecf_id }),
        )
      end

      it "does not touch the user's applications" do
        application = create(:application, user:)

        subject.archive!(blank_email: true)

        expect(application.reload.user).to eq(user)
      end
    end

    context "when there is already a user with the archived email" do
      before do
        create(:user, :archived, archived_email: "test1@example.com")
      end

      it "archives user by appending a unique prefix to the email" do
        subject.archive!

        expect(user).to be_archived
        expect(user.archived_email).to eq("test1@example.com")
        expect(user.email).to eq("archived-2-test1@example.com")
      end
    end
  end

  describe ".set_uid_to_nil!" do
    let(:user) { create(:user, :archived, :with_get_an_identity_id) }

    it "sets uid to nil" do
      subject.set_uid_to_nil!

      expect(user.uid).to be_nil
    end
  end
end
