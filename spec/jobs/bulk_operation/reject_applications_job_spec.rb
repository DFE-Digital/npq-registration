require "rails_helper"

RSpec.describe BulkOperation::RejectApplicationsJob do
  describe "#perform" do
    subject { described_class.new.perform(bulk_operation_id:) }

    let(:bulk_operation) { create(:reject_applications_bulk_operation, admin: create(:admin), file: uploaded_file) }
    let(:bulk_operation_id) { bulk_operation.id }
    let(:file) { tempfile_with_bom application_ecf_ids.join("\n") }
    let(:uploaded_file) { Rack::Test::UploadedFile.new(file.path) }
    let(:application_ecf_ids) { [SecureRandom.uuid, SecureRandom.uuid] }

    it "calls BulkOperation::BulkRejectApplications" do
      expect(BulkOperation::BulkRejectApplications).to receive(:new).with(bulk_operation:).and_call_original
      subject
    end

    it "sets finished_at" do
      subject
      expect(bulk_operation.reload.finished_at).to be_present
    end
  end
end
