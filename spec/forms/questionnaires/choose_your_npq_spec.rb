require "rails_helper"

RSpec.describe Questionnaires::ChooseYourNpq, type: :model do
  subject(:instance) { described_class.new(wizard:, course_identifier: course.identifier) }

  let(:wizard) { RegistrationWizard.new(current_step: :choose_your_npq, store:, request: nil, current_user: nil) }
  let(:store) { {} }
  let(:aso_course) { Course.find_by(identifier: "npq-additional-support-offer") }
  let(:ehco_course) { Course.find_by(identifier: "npq-early-headship-coaching-offer") }
  let(:headship_course) { Course.find_by(identifier: "npq-headship") }
  let(:leading_behaviour_culture_course) { Course.find_by(identifier: "npq-leading-behaviour-culture") }
  let(:leading_primary_mathematics_course) { Course.find_by(identifier: "npq-leading-primary-mathematics") }
  let(:leading_teaching_course) { Course.find_by(identifier: "npq-leading-teaching") }
  let(:leading_literacy_course) { Course.find_by(identifier: "npq-leading-literacy") }
  let(:senco_course) { Course.find_by(identifier: "npq-senco") }
  let(:course) { leading_behaviour_culture_course }

  describe "validations" do
    let(:valid_course_identifier) { ehco_course.identifier }
    let(:cohort) { create(:cohort, :next, :with_all_courses_for_provider, suffix: "b") }
    let(:store) { { course_start_cohort: cohort.identifier }.stringify_keys }

    it { is_expected.to validate_presence_of(:course_identifier) }

    it "the course must be available to the applicant" do
      subject.course_identifier = create(:course, :additional_support_offer).identifier
      subject.valid?
      expect(subject.errors[:course_identifier]).to be_present

      subject.course_identifier = valid_course_identifier
      subject.valid?
      expect(subject.errors[:course_identifier]).to be_blank
    end

    it "the course must be offered in the chosen cohort" do
      cohort.course_cohorts.find_by(course: leading_literacy_course).destroy!

      subject.course_identifier = leading_literacy_course.identifier
      subject.valid?
      expect(subject.errors[:course_identifier]).to be_present
    end
  end

  describe "#options" do
    let(:cohort) { create(:cohort, :next, :with_all_courses_for_provider, suffix: "b") }

    before do
      subject.wizard = RegistrationWizard.new(
        current_step: :choose_your_npq,
        store: { "course_start_cohort" => cohort.identifier },
        request: nil,
        current_user: create(:user),
      )
    end

    it "only offer courses a lead provider delivers in the chosen cohort" do
      expect(subject.options.map(&:value)).to include(leading_literacy_course.identifier)

      cohort.course_cohorts.find_by(course: leading_literacy_course).destroy!

      expect(subject.options.map(&:value)).not_to include(leading_literacy_course.identifier)
    end

    it "does not offer a course whose only lead provider was removed from the cohort" do
      cohort.course_cohorts.find_by(course: senco_course).course_cohort_providers.destroy_all

      expect(subject.options.map(&:value)).not_to include(senco_course.identifier)
    end
  end

  describe "#next_step" do
    subject { instance.next_step }

    it { is_expected.to be(:funding_history) }
  end

  describe "#previous_step" do
    subject { instance.previous_step }

    let(:store) do
      {
        course_start_cohort:,
        check_funding:,
        teacher_catchment:,
      }.stringify_keys
    end

    let(:check_funding) { nil }
    let(:teacher_catchment) { nil }

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
