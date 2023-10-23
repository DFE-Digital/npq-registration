require "rails_helper"

RSpec.describe AdminService::ApplicationsSearch do
  subject { described_class.new(q:) }

  let!(:application) { create(:application) }
  let!(:user) { application.user }

  describe "#call" do
    context "when partial email match" do
      let(:q) { user.email.split("@").first }

      it "returns the hit" do
        expect(subject.call).to include(application)
      end
    end

    context "when application#ecf_id match" do
      let(:q) { application.ecf_id }

      it "returns the hit" do
        expect(subject.call).to include(application)
      end
    end

    context "when user#ecf_id match" do
      let(:q) { user.ecf_id }

      it "returns the hit" do
        expect(subject.call).to include(application)
      end
    end
  end
end
