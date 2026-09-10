require "rails_helper"

RSpec.describe Questionnaires::FundingYourNpq, type: :model do
  subject(:instance) { described_class.new(wizard:) }

  let(:wizard) { RegistrationWizard.new(current_step: :funding_your_npq, store:, request: nil, current_user: nil) }
  let(:store) { {} }

  it { is_expected.to validate_inclusion_of(:funding).in_array(Questionnaires::FundingYourNpq::VALID_FUNDING_OPTIONS) }

  describe "#previous_step" do
    subject { instance.previous_step }

    it { is_expected.to eq(:ineligible_for_funding) }
  end

  describe "#next_step" do
    subject { instance.next_step }

    context "when the user has declared previous funding" do
      let(:store) { { declared_previous_funding: "yes" }.stringify_keys }

      it { is_expected.to eq(:work_setting) }
    end

    context "when the user has not declared previous funding" do
      let(:store) { { declared_previous_funding: "no" }.stringify_keys }

      it { is_expected.to eq(:choose_your_provider) }
    end
  end
end
