require "rails_helper"

RSpec.describe Questionnaires::PossibleFunding do
  subject(:instance) { described_class.new(wizard:) }

  let(:store) { {} }

  let(:wizard) do
    RegistrationWizard.new(
      current_step: :possible_funding,
      store:,
      request: nil,
      current_user: build(:user),
    )
  end

  describe "#previous_step" do
    subject { instance.previous_step }

    context "when the course is NPQLPM" do
      before { store["course_identifier"] = "npq-leading-primary-mathematics" }

      context "and maths_understanding is true" do
        before { store["maths_understanding"] = true }

        it { is_expected.to be(:maths_eligibility_teaching_for_mastery) }
      end

      context "and maths_understanding is false" do
        before { store["maths_understanding"] = false }

        it { is_expected.to be(:maths_understanding_of_approach) }
      end

      context "and maths_understanding is not set" do
        it { is_expected.to be(:maths_understanding_of_approach) }
      end
    end

    context "when the course is not NPQLPM" do
      before { store["course_identifier"] = "npq-senior-leadership" }

      context "when working for a lead mentor for an accredited initial teacher training (ITT) provider" do
        before { store["itt_provider"] = IttProvider.currently_approved.first.legal_name }

        it { is_expected.to be(:itt_provider) }
      end

      context "when the employment type is hospital school" do
        before { store["employment_type"] = Application.employment_types[:hospital_school] }

        it { expect(instance.previous_step).to eq(:your_employer) }
      end

      context "when the employment type is young offender institution" do
        before { store["employment_type"] = Application.employment_types[:young_offender_institution] }

        it { expect(instance.previous_step).to eq(:your_employer) }
      end

      context "when the employment type is neither hospital school nor young offender institution" do
        Application.employment_types.except(:hospital_school, :young_offender_institution).each do |employment_type|
          context "when the employment type is #{employment_type}" do
            before { store["employment_type"] = Application.employment_types[employment_type] }

            it { is_expected.to be(:work_setting) }
          end
        end
      end

      context "when the employment type is not set" do
        it { is_expected.to be(:work_setting) }
      end
    end

    context "when the course identifier is not set" do
      before { store["course_identifier"] = nil }

      it { is_expected.to be(:work_setting) }
    end
  end

  describe "#next_step" do
    subject { instance.next_step }

    it { is_expected.to be(:choose_your_provider) }
  end

  describe "#course" do
    subject { instance.course }

    let(:course) { create(:course, :early_years_leadership) }
    let(:store) { { "course_identifier" => course.identifier } }
    let(:request) { nil }

    it "reutrns the course undertaken" do
      expect(subject).to eql(course)
    end
  end

  describe "#message_template" do
    subject { instance.message_template }

    let(:course) { create(:course, :early_headship_coaching_offer) }
    let(:store) do
      { "course_identifier" => course.identifier,
        "employment_type" => "hospital_school",
        "teacher_catchment" => "england",
        "work_setting" => "another_setting" }
    end
    let(:request) { nil }
    let(:wizard) do
      RegistrationWizard.new(
        current_step: :possible_funding,
        store:,
        request:,
        current_user: create(:user),
      )
    end

    context "when eligibility can not be determined" do
      it "returns proper template" do
        expect(subject).to eq("funding_eligibility_unclear")
      end
    end
  end
end
