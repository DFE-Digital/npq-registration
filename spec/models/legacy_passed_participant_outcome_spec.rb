require "rails_helper"

RSpec.describe LegacyPassedParticipantOutcome do
  let(:instance) { described_class.new }

  describe "#course_name" do
    subject { instance.course_name }

    context "when there is a course for the given course_short_code" do
      let(:instance) { build(:legacy_passed_participant_outcome, course_short_code: course.short_code) }
      let(:course) { Course.find_by(short_code: "NPQH") }

      it { is_expected.to eq course.name }
    end

    context "when there is no course for the given course_short_code" do
      let(:instance) { build(:legacy_passed_participant_outcome, course_short_code: "NPQML") }

      it { is_expected.to eq "NPQML" }
    end
  end
end
