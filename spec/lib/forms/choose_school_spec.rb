require "rails_helper"

RSpec.describe Forms::ChooseSchool, type: :model do
  let(:current_step) { :choose_school }
  let(:store) { {} }
  let(:request) { nil }

  let(:wizard) do
    RegistrationWizard.new(current_step:, store:, request:, current_user: create(:user))
  end

  describe "validations" do
    subject do
      described_class.new(wizard:)
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

      # this is used for the sandbox environment
      it "can have institution_identifier as 'School-1234567'" do
        subject.institution_identifier = "School-1234567"
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
    subject { described_class.new(institution_identifier: "School-#{school.urn}", wizard:) }

    let(:course) { Course.all.sample }
    let(:store) do
      {
        "course_identifier" => course.identifier.to_s,
        "works_in_school" => "yes",
      }
    end
    let(:school) { create(:school) }

    it "goes to choose_your_npq" do
      expect(subject.next_step).to be(:choose_your_npq)
    end
  end
end
