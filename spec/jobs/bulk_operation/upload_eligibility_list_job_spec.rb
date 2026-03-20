require "rails_helper"

RSpec.describe BulkOperation::UploadEligibilityListJob do
  describe "#perform" do
    subject { described_class.new.perform(bulk_operation_id:) }

    let(:bulk_operation) { instance_double(BulkOperation::UploadEligibilityList, run!: {}) }
    let(:bulk_operation_id) { 1 }
    let(:eligibility_list_type) { "some_type" }

    before do
      allow(BulkOperation::UploadEligibilityList).to receive(:find).with(bulk_operation_id).and_return(bulk_operation)
    end

    it "runs the bulk operation" do
      expect(bulk_operation).to receive(:run!)
      subject
    end
  end
end
