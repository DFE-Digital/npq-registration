require "rails_helper"

RSpec.describe AdminService::UsersSearch do
  subject { described_class.new(q:) }

  let!(:user) { create(:user, preferred_name: "Jonny D") }
  let!(:application) do
    create(:application,
           user:)
  end

  describe "#call" do
    context "when partial email match" do
      let(:q) { user.email.split("@").first }

      it "returns the hit" do
        expect(subject.call).to include(user)
      end
    end

    context "when user#full_name match" do
      let(:q) { user.full_name }

      it "returns the hit" do
        expect(subject.call).to include(user)
      end
    end

    context "when user#preferred_name match" do
      let(:q) { user.preferred_name.split(" ").first }

      it "returns the hit" do
        expect(subject.call).to include(user)
      end
    end

    context "when user#ecf_id match" do
      let(:q) { user.ecf_id }

      it "returns the hit" do
        expect(subject.call).to include(user)
      end
    end

    context "when application#ecf_id match" do
      let(:q) { application.ecf_id }

      it "returns the hit" do
        expect(subject.call).to include(user)
      end
    end

    context "when user#trn match" do
      let(:q) { user.trn }

      it "returns the hit" do
        expect(subject.call).to include(user)
      end
    end

    context "when application#school_urn match" do
      let(:q) { application.school_urn }

      it "returns the hit" do
        expect(subject.call).to include(user)
      end
    end

    context "when application#private_childcare_provider_urn match" do
      let(:q) { application.DEPRECATED_private_childcare_provider_urn }

      it "returns the hit" do
        expect(subject.call).to include(user)
      end
    end

    context "when the user has multiple applications" do
      let(:q) { user.full_name }

      before do
        create(:application, user:)
      end

      it "returns one result" do
        expect(subject.call.count).to eq(1)
      end
    end

    context "when ordering results" do
      let!(:oldest_user) { create(:user, email: "oldest@example.com", created_at: 3.days.ago) }
      let!(:middle_user) { create(:user, email: "middle@example.com", created_at: 2.days.ago) }
      let!(:newest_user) { create(:user, email: "newest@example.com", created_at: 1.day.ago) }
      let(:q) { "example.com" }

      it "orders results by created_at DESC (newest first)" do
        results = subject.call
        expect(results.to_a).to eq([newest_user, middle_user, oldest_user])
      end
    end
  end
end
