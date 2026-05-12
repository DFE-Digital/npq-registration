require "rails_helper"

RSpec.describe Questionnaires::Start, type: :model do
  it { is_expected.to be_requirements_met }

  context "when running with new wizard" do
    subject { create(:registration_wizard, current_step: :start).current_step }

    it { is_expected.to be_dfe_wizard }
    it { is_expected.to be_invalid }
    it { is_expected.to validate_presence_of(:started) }
    it { is_expected.to validate_acceptance_of(:started) }
  end

  describe "#next_step?", skip: Rails.configuration.x.dfe_wizard do
    subject { instance.next_step }

    before { instance.wizard = wizard }

    let(:instance) { described_class.new }
    let(:wizard) { RegistrationWizard.new(store:, request:, current_step: :start, current_user:) }
    let(:request) { nil }
    let(:store) { {} }

    context "when logged in" do
      context "with TRN" do
        let(:current_user) { create :user }

        it { is_expected.to eq :course_start_date }
      end

      context "without TRN" do
        let(:current_user) { create :user, trn: nil }

        it { is_expected.to eq :teacher_reference_number }
      end
    end

    context "when not logged in" do
      let(:current_user) { nil }

      it { is_expected.to eq :start }
    end
  end
end
