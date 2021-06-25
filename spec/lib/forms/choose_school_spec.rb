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

    describe "#school_urn" do
      it "can have school_urn as empty string" do
        subject.school_urn = ""
        subject.valid?
        expect(subject.errors[:school_urn]).to be_blank
      end

      it "can have school_urn as 'other'" do
        subject.school_urn = "other"
        subject.valid?
        expect(subject.errors[:school_urn]).to be_blank
      end

      it "can have school_urn as '123456'" do
        subject.school_urn = "123456"
        subject.valid?
        expect(subject.errors[:school_urn]).to be_blank
      end

      it "cannot have school_urn as '1234567'" do
        subject.school_urn = "1234567"
        subject.valid?
        expect(subject.errors[:school_urn]).to be_present
      end
    end

    it { is_expected.to validate_length_of(:school_name).is_at_most(64) }
  end

  describe "#next_step" do
    let(:course) { Course.all.sample }
    let(:store) { { "course_id" => course.id.to_s } }
    let(:school) { create(:school) }

    subject { described_class.new(school_urn: school.urn, wizard: wizard) }

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
