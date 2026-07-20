require "rails_helper"

RSpec.describe Questionnaires::ChooseYourNpq, type: :model do
  let(:instance) { described_class.new(course_identifier: course.identifier) }
  let(:aso_course) { Course.find_by(identifier: "npq-additional-support-offer") }
  let(:ehco_course) { Course.find_by(identifier: "npq-early-headship-coaching-offer") }
  let(:headship_course) { Course.find_by(identifier: "npq-headship") }
  let(:leading_behaviour_culture_course) { Course.find_by(identifier: "npq-leading-behaviour-culture") }
  let(:leading_primary_mathematics_course) { Course.find_by(identifier: "npq-leading-primary-mathematics") }
  let(:leading_teaching_course) { Course.find_by(identifier: "npq-leading-teaching") }
  let(:senco_course) { Course.find_by(identifier: "npq-senco") }
  let(:course) { leading_behaviour_culture_course }

  describe "validations" do
    let(:valid_course_identifier) { ehco_course.identifier }

    it { is_expected.to validate_presence_of(:course_identifier) }

    it "course for course_id must be available to applicant" do
      subject.course_identifier = create(:course, :additional_support_offer).identifier
      subject.valid?
      expect(subject.errors[:course_identifier]).to be_present

      subject.course_identifier = valid_course_identifier
      subject.valid?
      expect(subject.errors[:course_identifier]).to be_blank
    end
  end

  describe "#next_step" do
    subject { instance.next_step }

    let(:lead_provider) { create(:lead_provider) }
    let(:cohort) { create(:cohort, :next, suffix: "b") }

    let(:store) do
      {
        course_start_cohort: cohort.identifier,
        course_identifier: course.identifier,
        lead_provider_id: lead_provider.id,
      }.stringify_keys
    end

    before do
      instance.wizard = RegistrationWizard.new(
        current_step: :choose_your_npq,
        store:,
        request: nil,
        current_user: create(:user),
      )
    end

    context "when changing answers" do
      before do
        instance.flag_as_changing_answer
      end

      context "when changing to something other than headship" do
        let(:course) { leading_teaching_course }
        let(:school) { create(:school) }
        let(:previous_course) { headship_course }
        let(:store) do
          {
            course_start_cohort: cohort.identifier,
            course_identifier: previous_course.identifier,
            institution_identifier: "School-#{school.urn}",
            works_in_school: "yes",
            lead_provider_id: lead_provider.id,
          }.stringify_keys
        end

        context "when lead provider is valid for new course" do
          let(:cohort) { create(:cohort, :next, :with_all_courses_for_provider, suffix: "b", lead_provider:) }

          it { is_expected.to be(:check_answers) }

          context "when nothing was actually changed" do
            let(:previous_course) { ehco_course }
            let(:course) { ehco_course }

            it { is_expected.to be :check_answers }
          end
        end

        context "when lead provider is not valid for new course" do
          it { is_expected.to be :ineligible_for_funding }
        end
      end
    end

    context "when the course is EHCO" do
      let(:course) { ehco_course }

      it { is_expected.to be(:npqh_status) }
    end

    context "when the course is NPQLPM" do
      let(:course) { leading_primary_mathematics_course }

      it { is_expected.to be(:maths_eligibility_teaching_for_mastery) }
    end

    context "when the course is NPQS" do
      let(:course) { senco_course }

      it { is_expected.to be(:senco_in_role) }
    end

    context "when the funding eligibility status is eligible" do
      before do
        allow_any_instance_of(FundingEligibility).to receive(:funding_eligiblity_status_code).and_return(:funded)
      end

      it { is_expected.to be :possible_funding }
    end

    context "when the funding eligibility status is subject to review" do
      before do
        allow_any_instance_of(FundingEligibility).to receive(:funding_eligiblity_status_code).and_return(:subject_to_review)
      end

      it { is_expected.to be :possible_funding }
    end

    context "when the funding eligibility status is ineligible" do
      before do
        allow_any_instance_of(FundingEligibility).to receive(:funding_eligiblity_status_code).and_return(:ineligible_institution_type)
      end

      it { is_expected.to be :ineligible_for_funding }
    end
  end

  describe "#previous_step" do
    let(:store) do
      {
        course_start_cohort:,
        check_funding:,
        teacher_catchment:,
      }.stringify_keys
    end

    let(:check_funding) { nil }
    let(:teacher_catchment) { nil }

    subject { instance.previous_step }

    before do
      instance.wizard = RegistrationWizard.new(
        current_step: :choose_your_npq,
        store:,
        request: nil,
        current_user: create(:user),
      )
    end

    context "when the course started in a funded cohort" do
      let(:course_start_cohort) { create(:cohort, :capped).identifier }

      context "when the user chose to check funding" do
        let(:check_funding) { "yes" }

        context "when the user is inside the catchment" do
          let(:teacher_catchment) { "england" }

          it { is_expected.to be :teacher_catchment }
        end

        context "when the user is outside the catchment" do
          let(:teacher_catchment) { "another" }

          it { is_expected.to be :ineligible_for_funding }
        end
      end

      context "when the user chose not to check funding" do
        let(:check_funding) { "no" }

        it { is_expected.to be :check_funding }
      end
    end

    context "when the course started in an unfunded cohort" do
      let(:course_start_cohort) { create(:cohort, :unfunded).identifier }

      it { is_expected.to be :course_start_date }
    end
  end
end
