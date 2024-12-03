require "rails_helper"

RSpec.describe OneOff::BulkChangeApplicationsToPending do
  let(:application_ecf_ids) { [application.ecf_id] }
  let(:instance) { described_class.new(application_ecf_ids:) }

  describe "#run!" do
    let(:dry_run) { false }

    subject(:run) { instance.run!(dry_run:) }

    RSpec.shared_examples "changes to pending" do |initial_state|
      it { expect { run }.to(change { application.reload.lead_provider_approval_status }.from(initial_state).to("pending")) }
      it { expect(run[application.ecf_id]).to eq("Changed to pending") }
    end

    RSpec.shared_examples "does not change to pending" do |result|
      it { expect { run }.not_to(change { application.reload.lead_provider_approval_status }) }
      it { expect(run[application.ecf_id]).to match(result) }
    end

    context "when there is an accepted application" do
      let(:application) { create(:application, :accepted) }

      it_behaves_like "changes to pending", "accepted"
    end

    context "when there is a rejected application" do
      let(:application) { create(:application, :rejected) }

      it_behaves_like "changes to pending", "rejected"
    end

    %i[submitted voided ineligible].each do |state|
      context "when the application has #{state} declarations" do
        let(:declaration) { create(:declaration, state) }

        context "when the application is accepted" do
          let(:application) { declaration.application }

          it_behaves_like "changes to pending", "accepted"
        end

        context "when the application is rejected" do
          let(:application) do
            declaration.application.tap do |application|
              application.update!(lead_provider_approval_status: "rejected")
            end
          end

          it_behaves_like "changes to pending", "rejected"
        end
      end
    end

    context "when the application is already pending" do
      let(:application) { create(:application, :pending) }

      it_behaves_like "does not change to pending", /lead provider approval status is not Accepted/
    end

    context "when the application doesn't exist" do
      let(:application_ecf_id) { SecureRandom.uuid }
      let(:application_ecf_ids) { [application_ecf_id] }

      it { expect(run[application_ecf_id]).to eq("Not found") }
    end

    Declaration.states.keys.excluding("submitted", "voided", "ineligible").each do |state|
      context "when the application has #{state} declarations" do
        let(:declaration) { create(:declaration, state) }
        let(:application) { declaration.application }

        it_behaves_like "does not change to pending", /There are already declarations for this participant/
      end
    end

    context "when dry_run is true" do
      let(:dry_run) { true }

      let(:application) { create(:application, :accepted) }

      it { expect { run }.not_to(change { application.reload.lead_provider_approval_status }) }
      it { expect(run[application.ecf_id]).to eq("Changed to pending") }
    end
  end
end
