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
    let(:store) do
      {
        "course_id" => course.id,
        "institution_identifier" => "School-#{school.urn}",
      }
    end
    let(:wizard) do
      RegistrationWizard.new(
        current_step: current_step,
        store: store,
        request: request,
      )
    end
    let(:mock_funding_service) { instance_double(Services::FundingEligibility, call: true) }

    context "when npqh and eligible for funding" do
      before do
        subject.wizard = wizard
        allow(Services::FundingEligibility).to receive(:new).and_return(mock_funding_service)
      end

      it "returns :possible_funding" do
        expect(subject.previous_step).to eql(:possible_funding)
      end
    end
  end
end
