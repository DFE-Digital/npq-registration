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

  describe "#next_step" do
    subject { instance.next_step }

    it { is_expected.to eq(:choose_your_provider) }
  end
end
