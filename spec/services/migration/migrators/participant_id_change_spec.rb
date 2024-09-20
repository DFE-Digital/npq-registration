require "rails_helper"

RSpec.describe Migration::Migrators::ParticipantIdChange do
  it_behaves_like "a migrator", :participant_id_change, %i[user] do
    def create_ecf_resource
      user = create(:ecf_migration_user, :npq)
      create(:ecf_migration_participant_id_change, user:)
    end

    def create_npq_resource(ecf_resource)
      create(:user, ecf_id: ecf_resource.user.id)
      create(:user, ecf_id: ecf_resource.from_participant.id)
      create(:user, ecf_id: ecf_resource.to_participant.id)

      create(:participant_id_change, ecf_id: ecf_resource.id)
    end

    def setup_failure_state
      # Corresponding users were not migrated from ECF.
      user = create(:ecf_migration_user, :npq)
      create(:ecf_migration_participant_id_change, user:)
    end

    describe "#call" do
      it "sets the created ParticipantIdChange attributes correctly" do
        instance.call

        participant_id_change = ParticipantIdChange.find_by!(ecf_id: ecf_resource1.id)
        expect(participant_id_change).to have_attributes({
          user_id: User.find_by(ecf_id: ecf_resource1.user_id).id,
          from_participant_id: User.find_by(ecf_id: ecf_resource1.from_participant_id).id,
          to_participant_id: User.find_by(ecf_id: ecf_resource1.to_participant_id).id,
          created_at: ecf_resource1.created_at,
        })
      end
    end
  end
end
