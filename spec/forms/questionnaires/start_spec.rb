require "rails_helper"

RSpec.describe Questionnaires::Start, type: :model do
  subject(:instance) { described_class.new(wizard:) }

  let(:wizard) { RegistrationWizard.new(store: {}, request: nil, current_step: :start, current_user: nil) }

  it { is_expected.to be_requirements_met }

  context "when running with new wizard" do
    subject { create(:registration_wizard, current_step: :start).current_step }

    it { is_expected.to be_dfe_wizard }
    it { is_expected.to be_invalid }
    it { is_expected.to validate_presence_of(:started) }
    it { is_expected.to validate_acceptance_of(:started) }
  end

  describe "#next_step", skip: Rails.configuration.x.dfe_wizard do
    subject { instance.next_step }

    it { is_expected.to eq :course_start_date }
  end
end
