require "rails_helper"

RSpec.describe Migration::Migrators::User do
  it_behaves_like "a migrator", :user, [] do
    def create_ecf_resource
      create(:ecf_migration_user, :npq)
    end

    def create_npq_resource(ecf_resource)
      create(:user, :with_random_name, ecf_id: ecf_resource.id, email: ecf_resource.email)
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
        create(:ecf_migration_npq_application, teacher_reference_number: "123456", teacher_reference_number_verified: true, participant_identity: ecf_user.participant_identities.first)
        instance.call
        expect(failure_manager).to have_received(:record_failure).with(ecf_user, /There are multiple different TRNs from NPQ applications/)
      end

      it "does not record a failure if there are multiple, unverified TRNs for the user's NPQApplications in ECF" do
        ecf_user = create(:ecf_migration_user, :npq)
        create(:ecf_migration_npq_application, teacher_reference_number: "123456", teacher_reference_number_verified: false, participant_identity: ecf_user.participant_identities.first)
        instance.call
        expect(failure_manager).not_to have_received(:record_failure)
      end

      it "records a failure when there are multiple emails" do
        ecf_user = create(:ecf_migration_user, :npq, email: "email-1@example.com")
        participant_identity = create(:ecf_migration_participant_identity, user: ecf_user, email: "email-2@example.com", external_identifier: SecureRandom.uuid)
        create(:ecf_migration_npq_application, teacher_reference_number: ecf_user.npq_applications.first.teacher_reference_number, participant_identity:)

        instance.call
        expect(failure_manager).to have_received(:record_failure).with(ecf_user, /There are multiple different emails from user identities in NPQ applications/)
      end

      it "records a failure when existing email in npq does not match ecf email" do
        ecf_user = create(:ecf_migration_user, :npq, email: "email-1@example.com")
        create(:user, ecf_id: ecf_user.id, email: "email-2@example.com")

        instance.call
        expect(failure_manager).to have_received(:record_failure).with(ecf_user, /Participant identity email from ECF does not match existing user email in NPQ/)
      end

      it "sets User attributes from recent updated npq application" do
        ecf_user = travel_to 5.days.ago do
          create(:ecf_migration_user, :npq, email: "joe@example.com")
        end

        create(
          :ecf_migration_npq_application,
          participant_identity: ecf_user.participant_identities.first,
          teacher_reference_number: ecf_user.npq_applications.first.teacher_reference_number,
          date_of_birth: "1980-01-01",
          nino: "XXX123",
          active_alert: true,
          teacher_reference_number_verified: true,
        )

        instance.call

        user = User.find_by(ecf_id: ecf_user.id)
        expect(user).to have_attributes(
          date_of_birth: "1980-01-01".to_date,
          national_insurance_number: "XXX123",
          active_alert: true,
          trn_verified: true,
        )
      end
    end
  end
end
