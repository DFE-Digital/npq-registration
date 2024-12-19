require "rails_helper"

RSpec.describe BulkOperation::BulkChangeApplicationsToPendingJob do
  describe "#perform" do
    subject { described_class.new.perform(bulk_operation_id:) }

    let(:bulk_operation) { create(:revert_applications_to_pending_bulk_operation, admin: create(:admin), file: uploaded_file) }
    let(:bulk_operation_id) { bulk_operation.id }
    let(:file) do
      Tempfile.new.tap do |file|
        file.write application_ecf_ids.join("\n")
        file.rewind
      end
    end
    let(:uploaded_file) { Rack::Test::UploadedFile.new(file.path) }
    let(:application_ecf_ids) { [SecureRandom.uuid, SecureRandom.uuid] }

    it "calls BulkOperation::BulkChangeApplicationsToPending" do
      expect(BulkOperation::BulkChangeApplicationsToPending).to receive(:new).with(application_ecf_ids:).and_call_original
      subject
    end

    it "sets finished_at" do
      subject
      expect(bulk_operation.reload.finished_at).to be_present
    end
  end
end
