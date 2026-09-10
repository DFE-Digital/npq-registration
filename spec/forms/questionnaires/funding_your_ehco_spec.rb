require "rails_helper"

RSpec.describe Questionnaires::FundingYourEhco, type: :model do
  subject(:instance) { described_class.new(wizard:) }

  let(:wizard) { RegistrationWizard.new(current_step: :funding_your_ehco, store:, request: nil, current_user: nil) }
  let(:declared_previous_funding) { nil }
  let(:teacher_catchment) { nil }

  let(:store) do
    {
      declared_previous_funding:,
      teacher_catchment:,
    }.stringify_keys
  end

  it { is_expected.to validate_inclusion_of(:ehco_funding_choice).in_array(Questionnaires::FundingYourEhco::VALID_FUNDING_OPTIONS) }

  describe "#previous_step" do
    subject { instance.previous_step }

    context "and the user has answered the catchment question" do
      context "and the user is outside the catchment" do
        let(:teacher_catchment) { "another" }

        it { is_expected.to be :work_setting }
      end
    end

    context "when the user has declared previous funding" do
      let(:declared_previous_funding) { "yes" }

      it { is_expected.to eq(:ineligible_for_funding_previously_funded) }
    end

    context "when the user has not declared previous funding" do
      let(:declared_previous_funding) { "no" }

      it { is_expected.to eq(:ineligible_for_funding) }
    end
  end

  describe "#next_step" do
    subject { instance.next_step }

    context "when the user has declared previous funding" do
      let(:declared_previous_funding) { "yes" }

      it { is_expected.to eq(:work_setting) }
    end

    context "when the user has not declared previous funding" do
      let(:declared_previous_funding) { "no" }

      it { is_expected.to eq(:choose_your_provider) }
    end
  end
end
