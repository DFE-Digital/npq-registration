require "rails_helper"

RSpec.describe Questionnaires::CheckFunding, type: :model do
  subject(:instance) { described_class.new(wizard:, check_funding:) }

  let(:current_step) { :check_funding }
  let(:wizard) { RegistrationWizard.new(current_step:, store: {}, request: nil, current_user: nil) }
  let(:check_funding) { "" }

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:check_funding).in_array(described_class::OPTIONS.keys) }
  end

  describe "#next_step" do
    subject { instance.next_step }

    context "when check_funding is 'yes'" do
      let(:check_funding) { "yes" }

      it { is_expected.to eq(:teacher_catchment) }
    end

    context "when check_funding is 'no'" do
      let(:check_funding) { "no" }

      it { is_expected.to eq(:choose_your_npq) }
    end
  end

  describe "#previous_step" do
    subject { instance.previous_step }

    it { is_expected.to eq(:course_start_date) }
  end
end
