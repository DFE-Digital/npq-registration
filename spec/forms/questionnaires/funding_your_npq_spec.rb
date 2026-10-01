require "rails_helper"

RSpec.describe Questionnaires::FundingYourNpq, type: :model do
  subject(:instance) { described_class.new(wizard:) }

  let(:wizard) { RegistrationWizard.new(current_step: :funding_your_npq, store:, request: nil, current_user: nil) }
  let(:store) { { teacher_catchment: }.stringify_keys }
  let(:teacher_catchment) { nil }

  it { is_expected.to validate_inclusion_of(:funding).in_array(Questionnaires::FundingYourNpq::VALID_FUNDING_OPTIONS) }

  describe "#next_step" do
    subject { instance.next_step }

    it { is_expected.to eq(:choose_your_provider) }
  end
end
