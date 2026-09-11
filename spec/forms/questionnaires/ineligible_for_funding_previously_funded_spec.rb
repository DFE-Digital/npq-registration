require "rails_helper"

RSpec.describe Questionnaires::IneligibleForFundingPreviouslyFunded, type: :model do
  subject(:instance) { described_class.new(wizard:) }

  let(:wizard) { RegistrationWizard.new(current_step: :ineligible_for_funding_previously_funded, store:, request: nil, current_user: nil) }
  let(:store) { {} }

  describe "#previous_step" do
    subject { instance.previous_step }

    it { is_expected.to eq(:funding_history) }
  end

  describe "#next_step" do
    subject { instance.next_step }

    it { is_expected.to eq(:work_setting) }
  end
end
