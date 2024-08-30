require "rails_helper"

RSpec.describe Migration::Migrators::User do
  it_behaves_like "a migrator", :user, [] do
    def create_ecf_resource
      create(:ecf_migration_user, :npq)
    end

    def create_npq_resource(ecf_resource)
      create(:user, :with_random_name, ecf_id: ecf_resource.id)
    end

    def setup_failure_state
      # UID has already been taken by another user with a different ecf_id.
      create(:ecf_migration_user, :npq, get_an_identity_id: "123456")
      create(:user, :with_random_name, uid: "123456")
    end

    describe "#call" do
      it "sets the created User attributes correctly" do
        user = User.find_by(ecf_id: ecf_resource1.id)
        instance.call
        expect(user.reload).to have_attributes(ecf_resource1.attributes.slice(:trn, :full_name, :email, :get_an_identity_id))
      end

      it "records a failure when there are multiple, different TRNs for the user's NPQApplications in ECF" do
        ecf_user = create(:ecf_migration_user, :npq)
        create(:ecf_migration_npq_application, teacher_reference_number: "123456", participant_identity: ecf_user.participant_identities.first)
        instance.call
        expect(failure_manager).to have_received(:record_failure).with(ecf_user, /There are multiple different TRNs from NPQ applications/)
      end
    end
  end
end
