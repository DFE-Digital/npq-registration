require "rails_helper"

RSpec.describe Migration::Migrators::ApplicationState do
  it_behaves_like "a migrator", :application_state, %i[application lead_provider] do
    def create_ecf_resource
      create(:ecf_migration_participant_profile_state)
    end

    def create_npq_resource(ecf_resource)
      create(:lead_provider, ecf_id: ecf_resource.cpd_lead_provider.npq_lead_provider.id)
      application = create(:application, :accepted, ecf_id: ecf_resource.participant_profile_id)
      create(:application_state, application:, ecf_id: ecf_resource.id)
    end

    def setup_failure_state
      # Application does not exist in NPQ reg
      participant_profile_state = create(:ecf_migration_participant_profile_state)
      create(:lead_provider, ecf_id: participant_profile_state.cpd_lead_provider.npq_lead_provider.id)
    end

    describe "#call" do
      it "sets the migrated ApplicationState attributes from ECF" do
        instance.call

        application_state = ApplicationState.joins(:application).find_by(application: { ecf_id: ecf_resource1.participant_profile_id })
        expect(application_state).to have_attributes(ecf_resource1.attributes.slice(%w[state reason created_at updated_at]))
        expect(application_state.lead_provider.ecf_id).to eq(ecf_resource1.cpd_lead_provider.npq_lead_provider.id)
      end

      it "records a failure when the lead provider can't be matched in NPQ reg" do
        participant_profile_state = create(:ecf_migration_participant_profile_state)
        create(:application, :accepted, ecf_id: participant_profile_state.participant_profile_id)

        instance.call

        expect(failure_manager).to have_received(:record_failure).once.with(participant_profile_state, /Couldn't find LeadProvider/)
      end
    end
  end
end
