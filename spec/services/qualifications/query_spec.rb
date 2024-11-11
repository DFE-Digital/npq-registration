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
      expected_outcomes = [
        latest_passed_participant_outcome,
        older_passed_participant_outcome_different_user_same_trn,
        older_passed_participant_outcome_different_declaration,
        older_passed_participant_outcome,
      ]
      expect(subject).to eq expected_outcomes
    end

    context "when there are no users with the specified TRN" do
      subject(:query) { described_class.new.qualifications(trn: non_existent_trn) }

      let(:non_existent_trn) { "0000000" }

      it "returns an empty array" do # TODO: or should this raise a NotFound error?
        expect(User.where(trn: non_existent_trn).count).to be_zero
        expect(subject).to be_empty
      end
    end
  end
end
