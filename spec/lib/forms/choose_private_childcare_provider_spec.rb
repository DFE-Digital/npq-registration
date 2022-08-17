require "rails_helper"

RSpec.describe Forms::ChoosePrivateChildcareProvider, type: :model do
  let(:current_step) { :choose_private_childcare_provider }
  let(:store) { { "works_in_childcare" => "yes" } }
  let(:request) { nil }

  let(:wizard) do
    RegistrationWizard.new(current_step:, store:, request:)
  end

  describe "validations" do
    before { create(:private_childcare_provider, provider_urn: "123456") }

    subject { described_class.new(wizard:) }

    describe "#institution_identifier" do
      it "can have institution_identifier as empty string" do
        subject.institution_identifier = ""
        expect(subject).to be_valid
      end

      it "can have institution_identifier as 'other'" do
        subject.institution_identifier = "other"
        expect(subject).to be_valid
      end

      it "can have institution_identifier as 'PrivateChildcareProvider-123456'" do
        subject.institution_identifier = "PrivateChildcareProvider-123456"
        expect(subject).to be_valid
      end

      it { is_expected.to validate_length_of(:institution_name).is_at_most(64) }
    end
  end

  describe "#next_step" do
    context "when institution_identifier is blank" do
      it "is choose_private_childcare_provider" do
        expect(subject.next_step).to eql(:choose_private_childcare_provider)
      end
    end

    context "when institution_identifier is present" do
      before { allow(subject).to receive(:institution_identifier).and_return("12345") }

      it "is choose_private_childcare_provider" do
        expect(subject.next_step).to eql(:choose_your_npq)
      end
    end
  end

  describe "#previous_step" do
    it { expect(subject.previous_step).to eql(:have_ofsted_urn) }
  end
end
