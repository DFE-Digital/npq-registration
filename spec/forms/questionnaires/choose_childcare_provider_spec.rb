require "rails_helper"

RSpec.describe Questionnaires::ChooseChildcareProvider, type: :model do
  subject :instance do
    described_class.new(wizard:,
                        childcare_identifier: identifier,
                        childcare_name: name)
  end

  let(:current_step) { :choose_childcare_provider }
  let(:store) { {} }
  let(:request) { nil }
  let(:identifier) { "" }
  let(:name) { "" }
  let(:provider) { create :school, urn: "8329422" }

  let(:wizard) do
    RegistrationWizard.new(current_step:, store:, request:, current_user: create(:user))
  end

  describe "validations" do
    let(:errors) { instance.tap(&:valid?).errors.to_hash }

    describe "#childcare_identifier" do
      it "can have childcare_identifier as empty string" do
        subject.childcare_identifier = ""
        subject.valid?
        expect(subject.errors[:childcare_identifier]).to be_blank
      end

      it "can have childcare_identifier as 'other'" do
        subject.childcare_identifier = "other"
        subject.valid?
        expect(subject.errors[:childcare_identifier]).to be_blank
      end

      it "can have childcare_identifier as 'School-123456'" do
        subject.childcare_identifier = "School-123456"
        subject.valid?
        expect(subject.errors[:childcare_identifier]).to be_blank
      end

      # this is used for the sandbox environment
      it "can have childcare_identifier as 'School-1234567'" do
        subject.childcare_identifier = "School-1234567"
        subject.valid?
        expect(subject.errors[:childcare_identifier]).to be_blank
      end

      it "can have childcare_identifier as 'LocalAuthority-1'" do
        subject.childcare_identifier = "LocalAuthority-1"
        subject.valid?
        expect(subject.errors[:childcare_identifier]).to be_blank
      end

      it "cannot have childcare_identifier as '1234567'" do
        subject.childcare_identifier = "1234567"
        subject.valid?
        expect(subject.errors[:childcare_identifier]).to be_present
      end
    end

    it { is_expected.to validate_length_of(:childcare_name).is_at_most(64) }

    context "when used from javascript autocomplete widget" do
      context "with institution valid" do
        let(:identifier) { "School-#{provider.urn}" }

        it { is_expected.to be_valid }
      end

      context "with no institution or name" do
        it { is_expected.to be_invalid }
        it { is_expected.not_to be_search_term_entered_in_no_js_fallback_form }
        it { expect(errors).to eq childcare_name: ["Enter a childcare provider"] }
      end

      context "with invalid institution" do
        let(:identifier) { "School-X" }

        it { is_expected.to be_invalid }
        it { is_expected.not_to be_search_term_entered_in_no_js_fallback_form }
        it { expect(errors).to eq childcare_identifier: ["No matching childcare provider found"] }
      end
    end

    context "when used from static input fields without javascript" do
      context "with institution valid" do
        let(:identifier) { "School-#{provider.urn}" }
        let(:name) { provider.name }

        it { is_expected.to be_valid }
      end

      context "with no institution or name" do
        it { is_expected.to be_invalid }
        it { is_expected.not_to be_search_term_entered_in_no_js_fallback_form }
        it { expect(errors).to eq childcare_name: ["Enter a childcare provider"] }
      end

      context "with workplace set to other" do
        let(:identifier) { "other" }
        let(:name) { provider.name }

        it { is_expected.to be_invalid }
        it { is_expected.to be_search_term_entered_in_no_js_fallback_form }
        it { expect(errors).to be_empty }
      end

      context "with workplace set to invalid value and other identifier" do
        let(:identifier) { "other" }
        let(:name) { "School-X" }

        it { is_expected.to be_invalid }
        it { is_expected.to be_search_term_entered_in_no_js_fallback_form }
        it { expect(errors).to eq childcare_name: ["No nurseries with the name School-X were found, please try again"] }
      end

      context "with workplace set to invalid value and blank identifier" do
        let(:name) { "School-X" }

        it { is_expected.to be_invalid }
        it { is_expected.to be_search_term_entered_in_no_js_fallback_form }
        it { expect(errors).to eq childcare_name: ["No nurseries with the name School-X were found, please try again"] }
      end

      context "with workplace set to other and not name" do
        let(:identifier) { "other" }

        it { is_expected.to be_invalid }
        it { is_expected.to be_search_term_entered_in_no_js_fallback_form }
        it { expect(errors).to eq childcare_name: ["Enter a childcare provider"] }
      end
    end
  end

  describe "#next_step" do
    subject { described_class.new(childcare_identifier: "School-#{provider.urn}", wizard:) }

    let(:course) { create(:course) }
    let(:store) do
      {
        "course_identifier" => course.identifier.to_s,
        "works_in_childcare" => "yes",
      }
    end
    let(:provider) { create(:school) }

    it "goes to choose_your_npq" do
      expect(subject.next_step).to be(:choose_your_npq)
    end
  end
end
