require "rails_helper"

RSpec.describe Migration::Migrators::ParticipantOutcome do
  # Without this the sent_to_qualified_teachers_api_at attribute is off my
  # a few microseconds in CI (its fine locally, strangely). I'm not sure why.
  around { |example| freeze_time { example.run } }

  it_behaves_like "a migrator", :participant_outcome, %i[declaration] do
    def create_ecf_resource
      create(:ecf_migration_participant_outcome)
    end

    def create_npq_resource(ecf_resource)
      create_declaration(ecf_id: ecf_resource.participant_declaration_id)
      create(:participant_outcome, ecf_id: ecf_resource.id)
    end

    def setup_failure_state
      # Outcome in ECF where the declaration hasn't been migrated to NPQ reg.
      create(:ecf_migration_participant_outcome)
    end

    describe "#call" do
      it "sets the created ParticipantOutcome attributes correctly" do
        instance.call
        outcome = ParticipantOutcome.find_by(ecf_id: ecf_resource1.id)
        expect(outcome).to have_attributes(ecf_resource1.attributes.except("id", "participant_declaration_id"))
        expect(outcome.declaration.ecf_id).to eq(ecf_resource1.participant_declaration_id)
      end
    end
  end
end
