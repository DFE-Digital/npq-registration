require "rails_helper"

RSpec.describe Users::Archiver do
  let(:user) { create(:user, email: "test1@example.com") }

  subject { described_class.new(user:) }

  describe ".archive!" do
    it "archives user" do
      expect(user).not_to be_archived

      subject.archive!

      expect(user.archived_email).to eq("test1@example.com")
      expect(user.email).to eq("archived-test1@example.com")
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
