require "rails_helper"

RSpec.describe Questionnaires::IneligibleForFunding, type: :model do
  subject(:instance) { described_class.new(wizard:) }

  let(:current_step) { :ineligible_for_funding }
  let(:wizard) { RegistrationWizard.new(current_step:, store: {}, request: nil, current_user: nil) }

  describe "#next_step" do
    subject { instance.next_step }

    context "when the user has not chosen a course" do
      it { is_expected.to eq(:choose_your_npq) }
    end

    context "when the user has chosen a course" do
      before { wizard.store["course_identifier"] = "npq-senior-leadership" }

      it { is_expected.to eq(:funding_your_npq) }
    end
  end

  describe "#previous_step" do
    subject { instance.previous_step }

    context "when the user has not chosen a course" do
      it { is_expected.to eq(:teacher_catchment) }
    end
  end
end
