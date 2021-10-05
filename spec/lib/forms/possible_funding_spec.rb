require "rails_helper"

RSpec.describe Forms::PossibleFunding do
  describe "#next_step" do
    it "returns choose_your_provider" do
      expect(subject.next_step).to eql(:choose_your_provider)
    end
  end

  describe "#previous_step" do
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

    context "studying for NPQH" do
      let(:course) { Course.find_by(name: "NPQ for Headship (NPQH)") }

      it "returns headteacher_duration" do
        expect(subject.previous_step).to eql(:headteacher_duration)
      end
    end

    context "studying for NPQ this is not NPQH or ASO" do
      let(:course) { Course.find_by(name: "NPQ for Senior Leadership (NPQSL)") }

      it "returns choose_your_npq" do
        expect(subject.previous_step).to eql(:choose_your_npq)
      end
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
