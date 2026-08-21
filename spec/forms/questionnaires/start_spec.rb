require "rails_helper"

RSpec.describe Questionnaires::Start do
  subject(:instance) { described_class.new(wizard:) }

  let(:wizard) { RegistrationWizard.new(store: {}, request: nil, current_step: :start, current_user: nil) }

  it { is_expected.to be_requirements_met }

  describe "#requirements_met?" do
    subject { instance.requirements_met? }

    it { is_expected.to be true }
  end

  describe "#next_step?" do
    subject { instance.next_step }

    it { is_expected.to eq :course_start_date }
  end
end
