require "rails_helper"

RSpec.describe Questionnaires::FundingEligibilitySenco, type: :model do
  subject(:instance) { described_class.new(wizard:) }

  let(:wizard) { RegistrationWizard.new(current_step: :funding_eligibility_senco, store:, request: nil, current_user: nil) }
  let(:store) { {} }

  describe "#previous_step" do
    subject { instance.previous_step }

    context "when the user works as a SENCO" do
      before { store["senco_in_role_status"] = true }

      it { is_expected.to eq(:senco_start_date) }
    end

    context "when the user does not work as a SENCO" do
      before { store["senco_in_role_status"] = false }

      it { is_expected.to eq(:senco_in_role) }
    end
  end

  describe "#next_step" do
    subject { instance.next_step }

    it { is_expected.to eq(:choose_your_provider) }
  end
end
