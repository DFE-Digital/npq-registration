require "rails_helper"

RSpec.describe Forms::ChooseSchool, type: :model do
  describe "validations" do
    let(:current_step) { :choose_school }
    let(:store) { {} }
    let(:request) { nil }

    let(:wizard) do
      RegistrationWizard.new(current_step: current_step, store: store, request: request)
    end

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
end
