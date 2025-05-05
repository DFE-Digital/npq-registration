require "rails_helper"

RSpec.describe BulkOperation::RevertApplicationsToPendingJob do
  describe "#perform" do
    subject { described_class.new.perform(bulk_operation_id:) }

    let(:bulk_operation) { instance_double(BulkOperation::RevertApplicationsToPending, run!: {}) }
    let(:bulk_operation_id) { 1 }

    before do
      allow(BulkOperation::RevertApplicationsToPending).to receive(:find).with(bulk_operation_id).and_return(bulk_operation)
    end

    it "runs the bulk operation" do
      expect(bulk_operation).to receive(:run!)
      subject
    end
  end
end
