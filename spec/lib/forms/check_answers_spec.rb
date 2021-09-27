require "rails_helper"

RSpec.describe Forms::CheckAnswers do
  let(:user) { create(:user) }
  let(:load_provider) { LeadProvider.all.sample }
  let(:course) { Course.all.sample }
  let(:school) { create(:school) }
  let(:verified_trn) { rand(1_000_000..9_999_999).to_s }
  let(:store) do
    {
      lead_provider_id: load_provider.id,
      institution_identifier: "School-#{school.urn}",
      course_id: course.id,
      trn_verified: true,
      trn: "1234567",
      verified_trn: verified_trn,
      confirmed_email: user.email,
    }.stringify_keys
  end
  let(:session) { {} }
  let(:request) { ActionController::TestRequest.new({}, session, ApplicationController) }
  let(:wizard) { RegistrationWizard.new(current_step: :check_answers, store: store, request: request) }

  describe "#after_save" do
    context "when verified_trn and entered trn differ" do
      it "uses verified_trn" do
        subject.wizard = wizard
        subject.after_save

        user.reload

        expect(user.trn).to eql(verified_trn)
      end
    end

    context "when trn_auto_verified is nil" do
      before do
        store["trn_auto_verified"] = nil
      end

      it "persists as false" do
        subject.wizard = wizard
        subject.after_save

        user.reload

        expect(user.trn_auto_verified).to eql(false)
      end
    end
  end

  describe "#previous_step" do
    let(:course) { Course.all.sample }
    let(:store) do
      {
        "course_id" => course.id.to_s,
        "institution_identifier" => "School-#{school.urn}",
      }
    end
    let(:school) { build(:school) }

    subject { described_class.new(wizard: wizard) }

    context "eligible_for_funding" do
      let(:funding_double) { instance_double(Services::FundingEligibility, call: true) }

      it "goes to possible_funding" do
        allow(Services::FundingEligibility).to receive(:new).and_return(funding_double)

        expect(subject.previous_step).to eql(:possible_funding)
      end
    end

    context "ineligible_for_funding" do
      let(:funding_double) { instance_double(Services::FundingEligibility, call: false) }

      it "goes to funding_your_npq" do
        allow(Services::FundingEligibility).to receive(:new).and_return(funding_double)

        expect(subject.previous_step).to eql(:funding_your_npq)
      end
    end
  end
end
