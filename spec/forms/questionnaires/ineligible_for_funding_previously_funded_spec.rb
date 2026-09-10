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

    context "when the user has chosen a course" do
      context "and the course is EHCO" do
        before { wizard.store["course_identifier"] = "npq-early-headship-coaching-offer" }

        it { is_expected.to eq(:funding_your_ehco) }
      end

      context "and the course is not EHCO" do
        before { wizard.store["course_identifier"] = "npq-senior-leadership" }

        it { is_expected.to eq(:funding_your_npq) }
      end
    end
  end
end
