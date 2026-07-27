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

    it { is_expected.to be(:funding_history) }
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
