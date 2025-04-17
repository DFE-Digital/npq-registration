require "rails_helper"

RSpec.describe BulkOperation::BulkUpdateAndVerifyTrns do
  let(:trns_to_update) { [[user1.ecf_id, "1234567"], [user2.ecf_id, "2345678"]] }
  let(:bulk_operation) { create(:update_and_verify_trns_bulk_operation, admin: create(:admin), trns_to_update:) }
  let(:instance) { described_class.new(bulk_operation:) }
  let(:user1) { create(:user, trn: "1000000") }
  let(:user2) { create(:user, trn: "1000001") }

  describe "#run!" do
    subject(:run) { instance.run! }

    it "updates the TRNs and trn_verifed" do
      expect { run }.to change { user1.reload.trn }.to("1234567")
        .and change { user1.reload.trn_verified }.to(true)
        .and change { user2.reload.trn }.to("2345678")
        .and change { user2.reload.trn_verified }.to(true)
    end

    it "saves the result" do
      run
      expect(JSON.parse(bulk_operation.result)[user1.ecf_id]).to match("TRN updated and verified")
      expect(JSON.parse(bulk_operation.result)[user2.ecf_id]).to match("TRN updated and verified")
    end

    context "when there is a validation error" do
      let(:trns_to_update) { [[user1.ecf_id, "0000000"]] }

      it "does not update the TRN" do
        expect { run }.not_to(change { user1.reload.trn })
      end

      it "saves the result" do
        run
        expect(JSON.parse(bulk_operation.result)[user1.ecf_id]).to match("You must enter a valid TRN")
      end
    end

    context "when the user does not exist" do
      let(:user_ecf_id) { SecureRandom.uuid }
      let(:trns_to_update) { [[user_ecf_id, "1234567"]] }

      it { expect(run[user_ecf_id]).to match("User not found") }
    end

    context "when the user ecf_id is not a valid UUID" do
      let(:user_ecf_id) { "invalid-uuid" }
      let(:trns_to_update) { [[user_ecf_id, "1234567"]] }

      it { expect(run[user_ecf_id]).to match("User not found") }
    end
  end
end
