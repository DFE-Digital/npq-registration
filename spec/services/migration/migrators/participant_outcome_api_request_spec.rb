require "rails_helper"

RSpec.describe Migration::Migrators::ParticipantOutcomeAPIRequest do
  it_behaves_like "a migrator", :participant_outcome_api_request, %i[participant_outcome] do
    def create_ecf_resource
      create(:ecf_migration_participant_outcome_api_request, :with_trn_success)
    end

    def create_npq_resource(ecf_resource)
      participant_outcome = create(:participant_outcome, ecf_id: ecf_resource.participant_outcome_id)
      create(:participant_outcome_api_request, :with_trn_success, participant_outcome:, ecf_id: ecf_resource.id)
    end

    def setup_failure_state
      # Participant Outcome Api Request in ECF where the Participant Outcome hasn't been migrated to NPQ reg.
      create(:ecf_migration_participant_outcome_api_request)
    end

    describe "#call" do
      it "sets the created ParticipantOutcomeAPIRequest attributes correctly" do
        instance.call

        outcome_api_request = ParticipantOutcomeAPIRequest.find_by(ecf_id: ecf_resource1.id)
        expect(outcome_api_request).to have_attributes(ecf_resource1.attributes.except("id", "participant_outcome_id"))
        expect(outcome_api_request.participant_outcome.ecf_id).to eq(ecf_resource1.participant_outcome_id)
      end
    end
  end
end
