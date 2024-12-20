require "rails_helper"

RSpec.describe AdminService::UsersSearch do
  subject { described_class.new(q:) }

  let!(:user) { create(:user) }
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
  end
end
