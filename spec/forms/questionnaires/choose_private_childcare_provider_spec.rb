require "rails_helper"

RSpec.describe Questionnaires::ChoosePrivateChildcareProvider, type: :model do
  subject :instance do
    described_class.new(wizard:,
                        private_childcare_identifier: identifier,
                        private_childcare_name: name)
  end

  let(:current_step) { :choose_private_childcare_provider }
  let(:store) { { "works_in_childcare" => "yes" } }
  let(:request) { nil }
  let(:identifier) { "" }
  let(:name) { "" }
  let(:provider) { create :private_childcare_provider, provider_urn: "8329422" }

  let(:wizard) do
    RegistrationWizard.new(current_step:, store:, request:, current_user: create(:user))
  end

  describe "validations" do
    let(:errors) { instance.tap(&:valid?).errors.to_hash }

    describe "#private_childcare_identifier" do
      before { create(:private_childcare_provider, provider_urn: "123456") }

      it "can have private_childcare_identifier as empty string" do
        subject.private_childcare_identifier = ""
        expect(subject).to be_invalid
        expect(errors).to eq private_childcare_name: ["Enter a private childcare provider"]
      end

      it "can have private_childcare_identifier as 'other'" do
        subject.private_childcare_identifier = "other"
        expect(subject).to be_invalid
        expect(errors).to eq private_childcare_name: ["Enter a private childcare provider"]
      end

      it "can have private_childcare_identifier as 'PrivateChildcareProvider-123456'" do
        subject.private_childcare_identifier = "PrivateChildcareProvider-123456"
        expect(subject).to be_valid
      end

      it "is invalid when the private_childcare_identifier contains a URN that doesn't exist" do
        missing_identifier = "PrivateChildcareProvider-000000"
        expected_message = "No private childcare providers with the URN 000000 were found, please try again"

        subject.private_childcare_identifier = missing_identifier

        expect(subject).to be_invalid
        expect(subject.errors.messages[:private_childcare_identifier]).to include(expected_message)
      end

      it "is invalid when the private_childcare_identifier is in the wrong format" do
        invalid_identifier = "PrivateChildcareProvider/999876"
        expected_message = "No matching private childcare provider found"

        subject.private_childcare_identifier = invalid_identifier

        expect(subject).to be_invalid
        expect(subject.errors.messages[:private_childcare_identifier]).to include(expected_message)
      end
    end

    it { is_expected.to validate_length_of(:private_childcare_name).is_at_most(64) }

    context "when used from javascript autocomplete widget" do
      context "with institution valid" do
        let(:identifier) { "PrivateChildcareProvider-#{provider.provider_urn}" }

        it { is_expected.to be_valid }
      end

      context "with no institution or name" do
        it { is_expected.to be_invalid }
        it { is_expected.not_to be_search_term_entered_in_no_js_fallback_form }
        it { expect(errors).to eq private_childcare_name: ["Enter a private childcare provider"] }
      end

      context "with invalid institution" do
        let(:identifier) { "PrivateChildcareProvider-X" }

        it { is_expected.to be_invalid }
        it { is_expected.not_to be_search_term_entered_in_no_js_fallback_form }
        it { expect(errors).to eq private_childcare_identifier: ["No private childcare providers with the URN X were found, please try again"] }
      end
    end

    context "when used from static input fields without javascript" do
      context "with institution valid" do
        let(:identifier) { "PrivateChildcareProvider-#{provider.provider_urn}" }
        let(:name) { provider.provider_name }

        it { is_expected.to be_valid }
      end

      context "with no institution or name" do
        it { is_expected.to be_invalid }
        it { is_expected.not_to be_search_term_entered_in_no_js_fallback_form }
        it { expect(errors).to eq private_childcare_name: ["Enter a private childcare provider"] }
      end

      context "with workplace set to other" do
        let(:identifier) { "other" }
        let(:name) { provider.provider_name }

        it { is_expected.to be_invalid }
        it { is_expected.to be_search_term_entered_in_no_js_fallback_form }
        it { expect(errors).to be_empty }
      end

      context "with workplace set to invalid value and other identifier" do
        let(:identifier) { "other" }
        let(:name) { "Something" }

        it { is_expected.to be_invalid }
        it { is_expected.to be_search_term_entered_in_no_js_fallback_form }
        it { expect(errors).to eq private_childcare_name: ["No private childcare providers with the URN Something were found, please try again"] }
      end

      context "with workplace set to invalid value and blank identifier" do
        let(:name) { "Something" }

        it { is_expected.to be_invalid }
        it { is_expected.to be_search_term_entered_in_no_js_fallback_form }
        it { expect(errors).to eq private_childcare_name: ["No private childcare providers with the URN Something were found, please try again"] }
      end

      context "with workplace set to other and not name" do
        let(:identifier) { "other" }

        it { is_expected.to be_invalid }
        it { is_expected.to be_search_term_entered_in_no_js_fallback_form }
        it { expect(errors).to eq private_childcare_name: ["Enter a private childcare provider"] }
      end
    end
  end

  describe "#next_step" do
    before { allow(subject).to receive(:private_childcare_identifier).and_return("12345") }

    it "is choose_private_childcare_provider" do
      expect(subject.next_step).to be(:choose_your_npq)
    end
  end

  describe "#previous_step" do
    it { expect(subject.previous_step).to be(:have_ofsted_urn) }
  end
end
