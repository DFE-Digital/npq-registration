require "rails_helper"

RSpec.describe Questionnaires::IneligibleForFunding, type: :model do
  subject(:instance) { described_class.new(wizard:) }

  let(:current_step) { :ineligible_for_funding }
  let(:wizard) { RegistrationWizard.new(current_step:, store:, request: nil, current_user: nil) }
  let(:store) { {} }

  describe "#previous_step" do
    subject { instance.previous_step }

    context "when the user has not chosen a course" do
      it { is_expected.to eq(:teacher_catchment) }
    end

    context "and the user has answered the catchment question" do
      context "and the user is outside the catchment" do
        let(:store) do
          {
            course_identifier: "npq-headship",
            teacher_catchment: "another",
          }.stringify_keys
        end

        it { is_expected.to be :teacher_catchment }
      end
    end

    context "when the course is EHCO" do
      let(:store) do
        {
          course_identifier: "npq-early-headship-coaching-offer",
          declared_previous_funding:,
        }.stringify_keys
      end

      context "when the user has declared previous funding" do
        let(:declared_previous_funding) { "yes" }

        it { is_expected.to eq(:funding_history) }
      end

      context "when the user has not declared previous funding" do
        let(:declared_previous_funding) { "no" }

        it { is_expected.to eq(:ehco_new_headteacher) }
      end
    end

    context "when the course is not EHCO, Leading primary mathematics, or SENCO" do
      let(:store) do
        {
          course_identifier: "npq-headship",
        }.stringify_keys
      end

      it { is_expected.to eq(:work_setting) }
    end
  end

  describe "#next_step" do
    subject { instance.next_step }

    context "when the user has not chosen a course" do
      it { is_expected.to eq(:choose_your_npq) }
    end

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
