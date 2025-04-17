require "rails_helper"

RSpec.describe BulkOperation::UpdateAndVerifyTrnsJob do
  describe "#perform" do
    subject { described_class.new.perform(bulk_operation_id:) }

    let(:bulk_operation) { create(:update_and_verify_trns_bulk_operation, admin: create(:admin), file: uploaded_file) }
    let(:bulk_operation_id) { bulk_operation.id }
    let(:header) { "User ID,Updated TRN\n" }
    let(:file) { tempfile_with_bom header + "#{user1.ecf_id},1234567\n#{user2.ecf_id},2345678\n" }
    let(:uploaded_file) { Rack::Test::UploadedFile.new(file.path) }
    let(:trns_to_update) { CSV.open(file, headers: true).read }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    before { allow(CSV).to receive(:read).and_return(trns_to_update) }

    it "calls BulkOperation::BulkUpdateAndVerifyTrns" do
      expect(BulkOperation::BulkUpdateAndVerifyTrns).to receive(:new).with(bulk_operation:).and_call_original
      subject
    end

    it "sets finished_at" do
      subject
      expect(bulk_operation.reload.finished_at).to be_present
    end
  end
end
