require "rails_helper"

RSpec.describe Forms::PossibleFunding do
  describe "#next_step" do
    it "returns check_answers" do
      expect(subject.next_step).to eql(:check_answers)
    end
  end

  describe "#previous_step" do
    it "returns choose_school" do
      expect(subject.previous_step).to eql(:choose_school)
    end
  end

  describe "#course" do
    let(:course) { Course.all.sample }
    let(:store) { { "course_id" => course.id } }
    let(:request) { nil }
    let(:wizard) do
      RegistrationWizard.new(
        current_step: :possible_funding,
        store: store,
        request: request,
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
