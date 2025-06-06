require "rails_helper"

RSpec.describe "update_legacy_passed_participant_outcomes" do
  describe "update_trn" do
    subject(:run_task) { Rake::Task["update_legacy_passed_participant_outcomes:update_trn"].invoke(old_trn, new_trn) }

    let(:legacy_outcome) { create(:legacy_passed_participant_outcome, trn: "1234567") }
    let(:another_legacy_outcome) { create(:legacy_passed_participant_outcome, trn: legacy_outcome.trn) }
    let(:legacy_outcome_with_different_trn) { create(:legacy_passed_participant_outcome, trn: "2345678") }
    let(:old_trn) { legacy_outcome.trn }
    let(:new_trn) { "1010101" }

    after { Rake::Task["update_legacy_passed_participant_outcomes:update_trn"].reenable }

    it "updates the TRN for legacy passed participant outcomes that have the specified old_trn" do
      run_task
      expect(legacy_outcome.reload.trn).to eq new_trn
      expect(another_legacy_outcome.reload.trn).to eq new_trn
    end

    it "does not update the TRN for legacy passed participant outcomes that do not have the specified old_trn" do
      run_task
      expect(legacy_outcome_with_different_trn.reload.trn).to eq "2345678"
    end

    context "when the old_trn is not provided" do
      let(:old_trn) { nil }

      it "raises an error" do
        expect { run_task }.to raise_error(RuntimeError, "Missing required argument: old_trn")
      end
    end

    context "when the new_trn is not provided" do
      let(:new_trn) { nil }

      it "raises an error" do
        expect { run_task }.to raise_error(RuntimeError, "Missing required argument: new_trn")
      end
    end

    context "when no legacy passed participant outcomes match the old_trn" do
      let(:old_trn) { "7777777" }

      it "raises an error" do
        expect { run_task }.to raise_error(RuntimeError, "No legacy passed participant outcomes found with TRN: 7777777")
      end
    end
  end
end
