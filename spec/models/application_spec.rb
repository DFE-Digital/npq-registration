require "rails_helper"

RSpec.describe Application do
  it { is_expected.to belong_to(:schedule).optional }

  describe "relationships" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:course) }
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to belong_to(:school).optional }
    it { is_expected.to belong_to(:private_childcare_provider).optional }
    it { is_expected.to belong_to(:itt_provider).optional }
    it { is_expected.to belong_to(:schedule).optional }

    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:declarations) }
    it { is_expected.to have_many(:ecf_sync_request_logs).dependent(:destroy) }
  end

  describe "scopes" do
    describe ".unsynced" do
      it "returns records where ecf_id is null" do
        expect(described_class.unsynced.to_sql).to match(%("ecf_id" IS NULL))
      end
    end
  end

  describe "#employer_name" do
    shared_examples "employer_name" do
      it "displays proper employer_name" do
        expect(application.employer_name_to_display).to eq(name)
      end
    end

    context "when the application has school attached" do
      let(:school) { create(:school) }
      let(:name) { school.name }
      let(:application) { build(:application, school:) }

      include_examples "employer_name"
    end

    context "when the application has private school urn" do
      let(:private_childcare_provider) { create(:private_childcare_provider) }
      let(:name) { private_childcare_provider.provider_name }
      let(:application) { build(:application, private_childcare_provider:) }

      include_examples "employer_name"
    end

    context "when application has employer_name" do
      let(:name) { "Employer Foo Bar" }
      let(:application) { build(:application, school: nil, school_id: nil, employer_name: name) }

      include_examples "employer_name"
    end

    context "when no information about employer_name is available" do
      let(:application) do
        let(:name) { "" }
        let(:application) { build(:application, school: nil, school_id: nil, employer_name: nil) }

        include_examples "employer_name"
      end
    end
  end

  describe "versioning" do
    context "when changing versioned fields" do
      let(:application) { create(:application, lead_provider_approval_status: "pending", participant_outcome_state: nil) }

      before do
        application.update!(lead_provider_approval_status: "accepted", participant_outcome_state: "passed")
      end

      it "has history of changes" do
        previous_application = application.versions.last.reify
        expect(application.lead_provider_approval_status).to eq("accepted")
        expect(application.participant_outcome_state).to eq("passed")

        expect(previous_application.lead_provider_approval_status).to eq("pending")
        expect(previous_application.participant_outcome_state).to eq(nil)
      end
    end
  end
end
