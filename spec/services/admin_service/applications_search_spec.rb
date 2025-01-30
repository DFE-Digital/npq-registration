require "rails_helper"

RSpec.describe AdminService::ApplicationsSearch do
  let(:service) { described_class.new(q:) }
  let!(:application) { create(:application, employer_name: Faker::Company.name) }
  let!(:user) { application.user }

  describe "#call" do
    subject { service.call }

    context "when email partially matches" do
      let(:q) { user.email.split("@").first }

      it { is_expected.to include(application) }
    end

    context "when name partially matches" do
      let(:q) { user.full_name.split(" ").first }

      it { is_expected.to include(application) }
    end

    context "when employer_name matches" do
      let(:q) { application.employer_name.split(" ").first }

      it { is_expected.to include(application) }
    end

    context "when school name matches" do
      let(:q) { application.school.name.split(" ").first }

      it { is_expected.to include(application) }
    end

    context "when application#ecf_id match" do
      let(:q) { application.ecf_id }

      it { is_expected.to include(application) }
    end

    context "when user#ecf_id match" do
      let(:q) { user.ecf_id }

      it { is_expected.to include(application) }
    end
  end
end
