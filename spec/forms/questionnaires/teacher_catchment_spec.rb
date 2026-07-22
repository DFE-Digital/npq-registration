require "rails_helper"

RSpec.describe Questionnaires::TeacherCatchment, type: :model do
  let(:wizard) { RegistrationWizard.new(current_step:, store: {}, request: nil, current_user: nil) }
  let(:current_step) { :teacher_catchment }
  let(:instance) { described_class.new(wizard:, teacher_catchment:) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:teacher_catchment) }
  end

  describe "#next_step" do
    subject { instance.next_step }

    context "when the user is in England" do
      let(:teacher_catchment) { "england" }

      it { is_expected.to eq(:choose_your_npq) }
    end

    context "when the user is not in England" do
      let(:teacher_catchment) { "another" }

      it { is_expected.to eq(:ineligible_for_funding) }
    end
  end

  describe "#previous_step" do
    subject { instance.previous_step }

    let(:teacher_catchment) { "another" }

    it { is_expected.to eq(:check_funding) }
  end
end
