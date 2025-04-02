require "rails_helper"

RSpec.describe Questionnaires::PossibleFunding do
  describe "#next_step" do
    it "returns choose_your_provider" do
      expect(subject.next_step).to be(:choose_your_provider)
    end
  end

  describe "#course" do
    let(:course) { create(:course, :early_years_leadership) }
    let(:store) { { "course_identifier" => course.identifier } }
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
