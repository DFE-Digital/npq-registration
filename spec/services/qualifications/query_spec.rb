require "rails_helper"

RSpec.describe Qualifications::Query do
  describe "#qualifications" do
    subject(:query) { described_class.new.qualifications(trn:) }

    let(:user) { create(:user) }
    let(:trn) { user.trn }
    let(:different_user_with_same_trn) { create(:user, trn:) }
    let!(:passed_participant_outcome_1) { create(:participant_outcome, :passed, user:) }
    let!(:passed_participant_outcome_2) { create(:participant_outcome, :passed, user:) }
    let!(:passed_participant_outcome_3) { create(:participant_outcome, :passed, user: different_user_with_same_trn) }

    it "returns the passed participant outcomes for the given TRN" do
      expect(subject).to include(passed_participant_outcome_1, passed_participant_outcome_2, passed_participant_outcome_3)
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
