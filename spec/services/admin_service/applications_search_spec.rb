require "rails_helper"

RSpec.describe AdminService::ApplicationsSearch do
  let(:service) { described_class.new(q:) }
  let!(:application) { create(:application, employer_name: Faker::Company.name) }
  let!(:user) { application.user }

  it "returns an application" do
    application = create(:application, employer_name: Faker::Company.name)
    user = application.user
    q = user.email.split("@").first

    service = AdminService::ApplicationsSearch.new(user.email.split("@").first)
    found_applications = service.call

    # this is fancy way too compare
    # found_applications == [application]
    expect(found_applications).to eq([application])
  end

  describe "#call" do
    subject { service.call }

    context "when email partially matches" do
      let(:q) { user.email.split("@").first }

      it { is_expected.to include(application) }

      context "and the application has no school relation" do
        before { application.update! school: nil, works_in_school: false }

        it { is_expected.to include(application) }
      end
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
