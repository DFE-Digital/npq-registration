require "rails_helper"

RSpec.describe Qualifications::Query do
  describe "#qualifications" do
    subject(:query) { described_class.new.qualifications(trn:) }

    let(:user) { create(:user) }
    let(:trn) { user.trn }
    let(:different_user_with_same_trn) { create(:user, trn:) }
    let!(:older_passed_participant_outcome) { create(:participant_outcome, :passed, user:, completion_date: 1.year.ago) }
    let!(:latest_passed_participant_outcome) { create(:participant_outcome, :passed, user:, declaration: older_passed_participant_outcome.declaration, course: older_passed_participant_outcome.course) }
    let!(:older_passed_participant_outcome_different_declaration) { create(:participant_outcome, :passed, user:, completion_date: 6.months.ago, course: older_passed_participant_outcome.course) }
    let!(:older_passed_participant_outcome_different_user_same_trn) { create(:participant_outcome, :passed, user: different_user_with_same_trn, completion_date: 1.month.ago, course: older_passed_participant_outcome.course) }

    it "returns the latest passed participant outcomes for the given TRN" do
      expect(subject).to eq [
        latest_passed_participant_outcome,
        older_passed_participant_outcome_different_user_same_trn,
        older_passed_participant_outcome_different_declaration,
        older_passed_participant_outcome,
      ]
    end

    context "when there are matching entries in legacy participant outcomes" do
      let!(:older_legacy_participant_outcome) { create(:legacy_passed_participant_outcome, trn:, completion_date: 2.years.ago) }
      let!(:less_old_legacy_participant_outcome) { create(:legacy_passed_participant_outcome, trn:, completion_date: 2.weeks.ago) }

      it "includes the legacy outcomes" do
        expect(subject).to eq [
          latest_passed_participant_outcome,
          less_old_legacy_participant_outcome,
          older_passed_participant_outcome_different_user_same_trn,
          older_passed_participant_outcome_different_declaration,
          older_passed_participant_outcome,
          older_legacy_participant_outcome,
        ]
      end
    end

    context "when there are matching entries in participant outcomes that are duplicates of legacy participant outcomes" do
      before do
        create(:legacy_passed_participant_outcome, trn:, course_short_code: older_passed_participant_outcome.course.short_code, completion_date: older_passed_participant_outcome.completion_date)
      end

      it "does not include duplicates" do
        expect(subject).to eq [
          latest_passed_participant_outcome,
          older_passed_participant_outcome_different_user_same_trn,
          older_passed_participant_outcome_different_declaration,
          older_passed_participant_outcome,
        ]
      end
    end

    context "when there are no users with the specified TRN" do
      subject(:query) { described_class.new.qualifications(trn: non_existent_trn) }

      let(:non_existent_trn) { "0000000" }

      it "returns an empty array" do
        expect(User.where(trn: non_existent_trn).count).to be_zero
        expect(subject).to be_empty
      end
    end
  end
end
