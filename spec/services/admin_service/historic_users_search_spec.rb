require "rails_helper"

RSpec.describe AdminService::HistoricUsersSearch do
  subject(:results) { described_class.new(q:).call.to_a }

  let(:q) { "1234567" }

  context "when a legacy outcome has a matching TRN" do
    let!(:legacy_outcome) { create(:legacy_passed_participant_outcome, trn: "1234567", completion_date: Date.new(2020, 7, 1)) }

    before { create(:legacy_passed_participant_outcome, trn: "7654321") }

    it "returns the TRN and completion date" do
      expect(results.map(&:trn)).to eq(%w[1234567])
      expect(results.first.completion_date).to eq(legacy_outcome.completion_date)
    end

    context "when the search is part of the TRN" do
      let(:q) { "2345" }

      it "returns the TRN" do
        expect(results.map(&:trn)).to eq(%w[1234567])
      end
    end

    context "when the search does not match" do
      let(:q) { "999" }

      it { is_expected.to be_empty }
    end

    context "when the TRN belongs to a user" do
      before { create(:user, trn: "1234567") }

      it { is_expected.to be_empty }
    end

    context "when a user has no TRN" do
      before { create(:user, trn: nil) }

      it "still returns the TRN" do
        expect(results.map(&:trn)).to eq(%w[1234567])
      end
    end
  end

  context "when a TRN has more than one legacy outcome" do
    before do
      create(:legacy_passed_participant_outcome, trn: "1234567", completion_date: Date.new(2019, 7, 1))
      create(:legacy_passed_participant_outcome, trn: "1234567", completion_date: Date.new(2021, 7, 1), course_short_code: "NPQH")
    end

    it "returns one row with the earliest completion date" do
      expect(results.map(&:trn)).to eq(%w[1234567])
      expect(results.first.completion_date).to eq(Date.new(2019, 7, 1))
    end
  end

  context "when more than one TRN matches" do
    let(:q) { "123" }

    before do
      create(:legacy_passed_participant_outcome, trn: "1230000", completion_date: Date.new(2019, 7, 1))
      create(:legacy_passed_participant_outcome, trn: "1231111", completion_date: Date.new(2021, 7, 1))
    end

    it "orders by completion date, newest first" do
      expect(results.map(&:trn)).to eq(%w[1231111 1230000])
    end
  end
end
