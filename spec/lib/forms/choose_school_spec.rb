require "rails_helper"

RSpec.describe Forms::ChooseSchool, type: :model do
  let(:current_step) { :choose_school }
  let(:store) { {} }
  let(:request) { nil }

  let(:wizard) do
    RegistrationWizard.new(current_step: current_step, store: store, request: request)
  end

  describe "validations" do
    subject do
      described_class.new(wizard: wizard)
    end

    describe "#institution_identifier" do
      it "can have institution_identifier as empty string" do
        subject.institution_identifier = ""
        subject.valid?
        expect(subject.errors[:institution_identifier]).to be_blank
      end

      it "can have institution_identifier as 'other'" do
        subject.institution_identifier = "other"
        subject.valid?
        expect(subject.errors[:institution_identifier]).to be_blank
      end

      it "can have institution_identifier as 'School-123456'" do
        subject.institution_identifier = "School-123456"
        subject.valid?
        expect(subject.errors[:institution_identifier]).to be_blank
      end

      it "can have institution_identifier as 'LocalAuthority-1'" do
        subject.institution_identifier = "LocalAuthority-1"
        subject.valid?
        expect(subject.errors[:institution_identifier]).to be_blank
      end

      it "cannot have institution_identifier as '1234567'" do
        subject.institution_identifier = "1234567"
        subject.valid?
        expect(subject.errors[:institution_identifier]).to be_present
      end
    end

    it { is_expected.to validate_length_of(:institution_name).is_at_most(64) }
  end

  describe "#next_step" do
    let(:course) { Course.all.sample }
    let(:store) { { "course_id" => course.id.to_s } }
    let(:school) { create(:school) }

    subject { described_class.new(institution_identifier: "School-#{school.urn}", wizard: wizard) }

    context "eligible_for_funding" do
      let(:funding_double) { instance_double(Services::FundingEligibility, call: true) }

      it "goes to check_answers" do
        allow(Services::FundingEligibility).to receive(:new).and_return(funding_double)

        expect(subject.next_step).to eql(:check_answers)
      end
    end

    context "ineligible_for_funding" do
      let(:funding_double) { instance_double(Services::FundingEligibility, call: false) }

      it "goes to funding_your_npq" do
        allow(Services::FundingEligibility).to receive(:new).and_return(funding_double)

        expect(subject.next_step).to eql(:funding_your_npq)
      end
    end
  end
end
