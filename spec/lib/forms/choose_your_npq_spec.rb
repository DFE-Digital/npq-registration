require "rails_helper"

RSpec.describe Forms::ChooseYourNpq, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:course_id) }

    it "course for course_id must exist" do
      subject.course_id = 0
      subject.valid?
      expect(subject.errors[:course_id]).to be_present

      subject.course_id = Course.first.id
      subject.valid?
      expect(subject.errors[:course_id]).to be_blank
    end
  end

  describe "#next_step" do
    subject do
      described_class.new(course_id: course.id.to_s)
    end

    context "when studying for headship" do
      let(:course) { Course.find_by(name: "NPQ for Headship (NPQH)") }

      it "returns headteacher_duration" do
        expect(subject.next_step).to eql(:headteacher_duration)
      end
    end

    context "when studying for headship" do
      let(:course) { Course.find_by(name: "NPQ for Headship (NPQH)") }

      it "returns headteacher_duration" do
        expect(subject.next_step).to eql(:headteacher_duration)
      end
    end

    context "when changing answers" do
      before do
        subject.flag_as_changing_answer
      end

      context "nothing was actually changed" do
        let(:course) { Course.find_by(name: "NPQ for Headship (NPQH)") }
        let(:store) { { course_id: course.id.to_s }.stringify_keys }
        let(:request) { nil }

        before do
          subject.wizard = RegistrationWizard.new(
            current_step: :choose_your_npq,
            store: store,
            request: request,
          )
        end

        it "returns check_answers" do
          expect(subject.next_step).to eql(:check_answers)
        end
      end

      context "when changing to headship" do
        let(:course) { Course.find_by(name: "NPQ for Headship (NPQH)") }
        let(:previous_course) { Course.first }
        let(:store) { { course_id: previous_course.id.to_s }.stringify_keys }
        let(:request) { nil }

        before do
          subject.wizard = RegistrationWizard.new(
            current_step: :choose_your_npq,
            store: store,
            request: request,
          )
        end

        it "returns headteacher_duration" do
          expect(subject.next_step).to eql(:headteacher_duration)
        end
      end

      context "when changing to something other than headship" do
        let(:course) { Course.first }
        let(:school) { create(:school) }
        let(:previous_course) { Course.find_by(name: "NPQ for Headship (NPQH)") }
        let(:store) { { course_id: previous_course.id.to_s, institution_identifier: "School-#{school.urn}" }.stringify_keys }
        let(:request) { nil }

        before do
          subject.wizard = RegistrationWizard.new(
            current_step: :choose_your_npq,
            store: store,
            request: request,
          )
        end

        it "returns check_answers" do
          expect(subject.next_step).to eql(:check_answers)
        end
      end
    end
  end
end
