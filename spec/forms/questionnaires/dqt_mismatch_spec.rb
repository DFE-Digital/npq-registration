require "rails_helper"

RSpec.describe Questionnaires::DqtMismatch do
  subject(:step) { described_class.new.tap { |s| s.wizard = wizard } }

  let(:request) { nil }
  let(:store) { {} }
  let(:wizard) { RegistrationWizard.new(store:, request:, current_step: :dqt_mismatch, current_user:) }
  let(:current_user) { create(:user) }

  describe "#next_step" do
    subject(:next_step) { step.next_step }

    it { is_expected.to be :course_start_date }
  end

  describe "#requirements_met" do
    it { is_expected.to be_requirements_met }

    context "when current_user is blank" do
      let(:current_user) { nil }

      it { is_expected.not_to be_requirements_met }
    end
  end
end
