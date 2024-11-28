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
  end
end
