require "rails_helper"

RSpec.describe Questionnaires::PossibleFunding do
  let(:store) { {} }

  let(:wizard) do
    RegistrationWizard.new(
      current_step: :possible_funding,
      store:,
      request: nil,
      current_user: build(:user),
    )
  end

  describe "#next_step" do
    it "returns choose_your_provider" do
      expect(subject.next_step).to be(:choose_your_provider)
    end
  end

  describe "#previous_step" do
    subject { described_class.new(wizard:).previous_step }

    context "when the course is NPQLPM" do
      before { wizard.store["course_identifier"] = "npq-leading-primary-mathematics" }

      context "and maths_understanding is true" do
        before { wizard.store["maths_understanding"] = true }

        it { is_expected.to be(:maths_eligibility_teaching_for_mastery) }
      end

      context "and maths_understanding is false" do
        before { wizard.store["maths_understanding"] = false }

        it { is_expected.to be(:maths_understanding_of_approach) }
      end

      context "and maths_understanding is not set" do
        it { is_expected.to be(:maths_understanding_of_approach) }
      end
    end

    context "when the course is not NPQLPM" do
      before { wizard.store["course_identifier"] = "npq-senior-leadership" }

      it { is_expected.to be(:choose_your_npq) }
    end

    context "when the course identifier is not set" do
      before { wizard.store["course_identifier"] = nil }

      it { is_expected.to be(:choose_your_npq) }
    end
  end

  describe "#course" do
    let(:course) { create(:course, :early_years_leadership) }
    let(:store) { { "course_identifier" => course.identifier } }
    let(:request) { nil }

    before do
      subject.wizard = wizard
    end

    it "reutrns the course undertaken" do
      expect(subject.course).to eql(course)
    end
  end

  describe "#message_template" do
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

    before do
      subject.wizard = wizard
    end

    context "when eligibility can not be determined" do
      it "returns proper template" do
        expect(subject.message_template).to eq("funding_eligibility_unclear")
      end
    end
  end
end
