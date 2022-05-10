require "rails_helper"

RSpec.describe Forms::ChooseYourProvider, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:lead_provider_id) }

    it "course for lead_provider_id must exist" do
      subject.lead_provider_id = 0
      subject.valid?
      expect(subject.errors[:lead_provider_id]).to be_present

      subject.lead_provider_id = LeadProvider.first.id
      subject.valid?
      expect(subject.errors[:lead_provider_id]).to be_blank
    end
  end

  describe "#previous_step" do
    let(:current_step) { "choose_your_provider" }
    let(:request) { nil }
    let(:course) { Course.find_by(name: "NPQ for Headship (NPQH)") }
    let(:school) { create(:school) }
    let(:works_in_school) { "yes" }
    let(:store) do
      {
        "teacher_catchment" => "england",
        "course_id" => course.id,
        "institution_identifier" => "School-#{school.urn}",
        "works_in_school" => works_in_school,
      }
    end
    let(:wizard) do
      RegistrationWizard.new(
        current_step: current_step,
        store: store,
        request: request,
      )
    end
    let(:mock_funding_service) { instance_double(Services::FundingEligibility, "funded?": true) }

    before do
      subject.wizard = wizard
    end

    context "when npqh and eligible for funding" do
      before do
        allow(Services::FundingEligibility).to receive(:new).and_return(mock_funding_service)
      end

      it "returns :possible_funding" do
        expect(subject.previous_step).to eql(:possible_funding)
      end
    end

    context "international journey" do
      let(:store) do
        {
          "teacher_catchment" => "another",
        }
      end

      it "returns :funding_your_npq" do
        expect(subject.previous_step).to eql(:funding_your_npq)
      end
    end

    context "when not working in school" do
      let(:works_in_school) { "no" }

      it "returns :funding_your_npq" do
        expect(subject.previous_step).to eql(:funding_your_npq)
      end
    end
  end
end
