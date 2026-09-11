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

    context "when the course is EHCO" do
      let(:course) { create(:course, :early_headship_coaching_offer) }

      it { is_expected.to eq("eligible_for_scholarship_funding_not_tsf") }
    end

    context "when the course is not EHCO" do
      let(:course) { create(:course, :early_years_leadership) }

      it { is_expected.to eq("funding_eligibility_unclear") }
    end
  end
end
