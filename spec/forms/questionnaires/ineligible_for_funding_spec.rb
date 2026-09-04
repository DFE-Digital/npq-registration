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

      context "and the user is inside the catchment" do
        context "when the user works in another setting" do
          let(:store) do
            {
              teacher_catchment: "england",
              course_identifier: "npq-headship",
              work_setting: Questionnaires::WorkSetting::ANOTHER_SETTING_SETTINGS.first,
              employment_type:,
            }.stringify_keys
          end

          context "when the employment type is other" do
            let(:employment_type) { Application.employment_types["other"] }

            it { is_expected.to eq(:choose_your_npq) }
          end

          context "when the employment type is hospital_school" do
            let(:employment_type) { Application.employment_types["hospital_school"] }

            it { is_expected.to eq(:your_employer) }
          end

          context "when the employment type is young_offender_institution" do
            let(:employment_type) { Application.employment_types["young_offender_institution"] }

            it { is_expected.to eq(:your_employer) }
          end

          Application.employment_types.keys.excluding(
            Application.employment_types["other"],
            Application.employment_types["hospital_school"],
            Application.employment_types["young_offender_institution"],
          ).each do |employment_type|
            let(:employment_type) { employment_type }

            context "when the employment type is #{employment_type}" do
              it { is_expected.to eq(:work_setting) }
            end
          end
        end
      end
    end

    context "when the course is EHCO" do
      let(:store) do
        {
          course_start_cohort:,
          course_identifier: "npq-early-headship-coaching-offer",
          declared_previous_funding:,
          ehco_new_headteacher:,
        }.stringify_keys
      end

      let(:declared_previous_funding) { nil }
      let(:ehco_new_headteacher) { nil }

      context "when the cohort is funded" do
        let(:course_start_cohort) { create(:cohort, :capped).identifier }

        context "when the user has declared previous funding" do
          let(:declared_previous_funding) { "yes" }

          it { is_expected.to eq(:ehco_new_headteacher) }
        end

        context "when the user has not declared previous funding" do
          let(:declared_previous_funding) { "no" }

          context "when the user is a new headteacher" do
            let(:ehco_new_headteacher) { "yes" }

            it { is_expected.to eq(:funding_history) }
          end

          context "when the user is not a new headteacher" do
            let(:ehco_new_headteacher) { "no" }

            it { is_expected.to eq(:ehco_new_headteacher) }
          end
        end
      end

      context "when the cohort is not funded" do
        let(:course_start_cohort) { create(:cohort, :unfunded).identifier }

        it { is_expected.to eq(:work_setting) }
      end
    end

    context "when the course is Leading primary mathematics" do
      let(:store) do
        {
          course_identifier: "npq-leading-primary-mathematics",
          maths_understanding:,
        }.stringify_keys
      end

      context "when maths_understanding is true" do
        let(:maths_understanding) { true }

        it { is_expected.to eq(:maths_eligibility_teaching_for_mastery) }
      end

      context "when maths_understanding is false" do
        let(:maths_understanding) { false }

        it { is_expected.to eq(:maths_understanding_of_approach) }
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
