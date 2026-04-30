require "rails_helper"

RSpec.describe Questionnaires::ChooseYourNpq, type: :model do
  let(:aso_course) { Course.find_by(identifier: "npq-additional-support-offer") }
  let(:ehco_course) { Course.find_by(identifier: "npq-early-headship-coaching-offer") }
  let(:headship_course) { Course.find_by(identifier: "npq-headship") }
  let(:leading_behaviour_culture_course) { Course.find_by(identifier: "npq-leading-behaviour-culture") }
  let(:leading_primary_mathematics_course) { Course.find_by(identifier: "npq-leading-primary-mathematics") }
  let(:leading_teaching_course) { Course.find_by(identifier: "npq-leading-teaching") }
  let(:senco_course) { Course.find_by(identifier: "npq-senco") }

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

    let(:instance) { described_class.new(course_identifier: course.identifier) }
    let(:course) { leading_behaviour_culture_course }
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
    let(:request) { nil }
    let(:store) do
      {
        teacher_catchment:,
        works_in_school:,
        works_in_childcare:,
        kind_of_nursery:,
        has_ofsted_urn:,
      }.stringify_keys
    end
    let(:teacher_catchment) { "another" }
    let(:works_in_school) { "no" }
    let(:works_in_childcare) { "no" }
    let(:kind_of_nursery) { nil }
    let(:has_ofsted_urn) { "no" }

    before do
      subject.wizard = RegistrationWizard.new(
        current_step: :choose_your_npq,
        store:,
        request:, current_user: create(:user)
      )
    end

    context "when inside catchment" do
      let(:teacher_catchment) { "england" }

      it "returns work_setting" do
        expect(subject.previous_step).to be(:work_setting)
      end

      context "when working in school" do
        let(:works_in_school) { "yes" }

        it "returns choose_school" do
          expect(subject.previous_step).to be(:choose_school)
        end
      end

      context "when working in childcare" do
        let(:works_in_childcare) { "yes" }

        it "return have_ofsted_urn" do
          expect(subject.previous_step).to be(:have_ofsted_urn)
        end

        context "when working for a public childcare provider" do
          let(:kind_of_nursery) { Questionnaires::KindOfNursery::KIND_OF_NURSERY_PUBLIC_OPTIONS.sample }

          it "return choose_childcare_provider" do
            expect(subject.previous_step).to be(:choose_childcare_provider)
          end
        end

        context "when working for a private childcare provider" do
          let(:kind_of_nursery) { Questionnaires::KindOfNursery::KIND_OF_NURSERY_PRIVATE_OPTIONS.sample }

          it "return have_ofsted_urn" do
            expect(subject.previous_step).to be(:have_ofsted_urn)
          end

          context "when user has declared they have an ofsted URN" do
            let(:has_ofsted_urn) { "yes" }

            it "return choose_private_childcare_provider" do
              expect(subject.previous_step).to be(:choose_private_childcare_provider)
            end
          end
        end
      end
    end
  end
end
