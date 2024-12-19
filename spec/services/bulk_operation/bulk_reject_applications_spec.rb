require "rails_helper"

RSpec.describe BulkOperation::BulkRejectApplications do
  let(:application_ecf_ids) { [application.ecf_id] }
  let(:instance) { described_class.new(application_ecf_ids:) }

  describe "#run!" do
    subject(:run) { instance.run! }

    RSpec.shared_examples "does not change to rejected" do |result|
      it { expect { run }.not_to(change { application.reload.lead_provider_approval_status }) }
      it { expect(run[application.ecf_id]).to match(result) }
    end

    context "when the application has lead_provider_approval_status: accepted" do
      let(:application) { create(:application, :accepted) }

      it_behaves_like "does not change to rejected", /Once accepted an application cannot change state/
    end

    context "when the application is already lead_provider_approval_status: rejected" do
      let(:application) { create(:application, :rejected) }

      it_behaves_like "does not change to rejected", /application has already been rejected/
    end

    context "when the application is lead_provider_approval_status: pending" do
      let(:application) { create(:application, :pending) }

      it { expect { run }.to(change { application.reload.lead_provider_approval_status }.from("pending").to("rejected")) }
      it { expect(run[application.ecf_id]).to eq("Changed to rejected") }
    end

    context "when the application does not exist" do
      let(:application_ecf_id) { SecureRandom.uuid }
      let(:application_ecf_ids) { [application_ecf_id] }
      let(:application) { nil }

      it { expect(run[application_ecf_id]).to match(/Not found/) }
    end
  end
end
