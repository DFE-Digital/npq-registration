require "rails_helper"

RSpec.describe LegacyPassedParticipantOutcome, type: :model do
  describe "#course_name" do
    subject { build(:legacy_passed_participant_outcome, course_short_code:).course_name }

    context "when a course has the short code" do
      let(:course_short_code) { "NPQH" }

      before { create(:course, :headship, name: "Headship (NPQH)", short_code: "NPQH") }

      it { is_expected.to eq("Headship (NPQH)") }
    end

    context "when no course has the short code" do
      let(:course_short_code) { "NPQML" }

      it { is_expected.to eq("NPQML") }
    end
  end

  describe ".for_display" do
    let!(:older) { create(:legacy_passed_participant_outcome, trn: "1234567", completion_date: Date.new(2019, 7, 1)) }
    let!(:newer) { create(:legacy_passed_participant_outcome, trn: "1234567", completion_date: Date.new(2021, 7, 1)) }

    before { create(:legacy_passed_participant_outcome, trn: "7654321") }

    it "returns the outcomes newest first" do
      expect(described_class.where(trn: "1234567").for_display).to eq([newer, older])
    end
  end
end
