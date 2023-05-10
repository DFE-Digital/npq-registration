require "rails_helper"

RSpec.describe Forms::PossibleFunding do
  describe "#next_step" do
    it "returns choose_your_provider" do
      expect(subject.next_step).to be(:choose_your_provider)
    end
  end

  describe "#previous_step" do
    it "returns choose_your_npq" do
      expect(subject.previous_step).to be(:choose_your_npq)
    end
  end

  describe "#course" do
    let(:course) { Course.all.sample }
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
end
