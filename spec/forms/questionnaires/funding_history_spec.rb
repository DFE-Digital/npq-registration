require "rails_helper"

RSpec.describe Questionnaires::FundingHistory, type: :model do
  subject(:instance) { described_class.new(wizard:, declared_previous_funding:) }

  let(:current_step) { :funding_history }
  let(:wizard) { RegistrationWizard.new(current_step:, store: {}, request: nil, current_user: nil) }
  let(:declared_previous_funding) { "" }

  describe "validations" do
    it { is_expected.to validate_presence_of(:declared_previous_funding) }
    it { is_expected.to validate_inclusion_of(:declared_previous_funding).in_array(described_class::OPTIONS.keys) }
  end

  describe "#next_step" do
    subject { instance.next_step }

    context "when declared_previous_funding is 'yes'" do
      let(:declared_previous_funding) { "yes" }

      it { is_expected.to eq(:ineligible_for_funding_previously_funded) }
    end

    context "when declared_previous_funding is 'no'" do
      let(:declared_previous_funding) { "no" }

      it { is_expected.to eq(:work_setting) }
    end
  end

  describe "#previous_step" do
    subject { instance.previous_step }

    it { is_expected.to eq(:choose_your_npq) }
  end
end
