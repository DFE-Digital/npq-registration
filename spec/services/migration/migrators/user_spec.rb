require "rails_helper"

class TmpFailureManager
  def initialize
    @failures = {}
  end

  def failures(user)
    @failures[user]
  end

  def record_failure(user, msg)
    @failures[user] = msg
  end
end

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

      context "when there are multiple users with the same ecf_id" do
        it "raises error" do
          ecf_user = create(:ecf_migration_user, :npq, email: "email-1@example.com")
          create(:user, ecf_id: ecf_user.id, email: "email-1@example.com")
          create(:user, ecf_id: ecf_user.id, email: "email-2@example.com")

          instance.call
          expect(failure_manager).to have_received(:record_failure).with(ecf_user, /ecf_user.id has multiple users in NPQ/)
        end
      end

      context "when no user exists with ecf_id or get_an_identity_id" do
        it "creates a new user" do
          ecf_user = create(:ecf_migration_user, :npq, get_an_identity_id: SecureRandom.uuid)

          expect(User.find_by(ecf_id: ecf_user.id)).to be_nil
          expect(User.find_by(uid: ecf_user.get_an_identity_id)).to be_nil

          instance.call

          expect(User.where(ecf_id: ecf_user.id).count).to eq(1)
          user = User.find_by(uid: ecf_user.get_an_identity_id)
          expect(user.ecf_id).to eq(ecf_user.id)
        end
      end

      context "when only one user exists with both ecf_id and get_an_identity_id" do
        it "updates the user" do
          ecf_user = create(:ecf_migration_user, :npq, get_an_identity_id: SecureRandom.uuid, full_name: "New Name")
          create(:user, email: ecf_user.email, ecf_id: ecf_user.id, uid: ecf_user.get_an_identity_id, full_name: "Old Name")

          instance.call

          expect(User.where(ecf_id: ecf_user.id).count).to eq(1)
          user = User.find_by(uid: ecf_user.get_an_identity_id)
          expect(user.ecf_id).to eq(ecf_user.id)
          expect(user.full_name).to eq("New Name")
        end
      end

      context "when one user exists with ecf_id only" do
        it "updates the user" do
          ecf_user = create(:ecf_migration_user, :npq, get_an_identity_id: SecureRandom.uuid, full_name: "New Name")
          create(:user, email: ecf_user.email, ecf_id: ecf_user.id, uid: SecureRandom.uuid, full_name: "Old Name")

          expect(User.where(ecf_id: ecf_user.id).count).to eq(1)
          expect(User.where(uid: ecf_user.get_an_identity_id).count).to eq(0)

          instance.call

          expect(User.where(ecf_id: ecf_user.id).count).to eq(1)
          user = User.find_by(uid: ecf_user.get_an_identity_id)
          expect(user.ecf_id).to eq(ecf_user.id)
          expect(user.full_name).to eq("New Name")
        end
      end

      context "when ecf_id and get_an_identity_id both return users and are different" do
        it "raises error" do
          ecf_user = create(:ecf_migration_user, :npq, email: "email-1@example.com", get_an_identity_id: SecureRandom.uuid)
          create(:user, ecf_id: ecf_user.id, email: "email-1@example.com")
          create(:user, uid: ecf_user.get_an_identity_id, email: "email-2@example.com")

          instance.call
          expect(failure_manager).to have_received(:record_failure).with(ecf_user, /ecf_user.id and ecf_user.get_an_identity_id both return User records, but they are different/)
        end
      end

      context "when NPQ user found with ecf_user.get_an_identity_id only" do
        let(:ecf_user) { create(:ecf_migration_user, :npq, email: "email-1@example.com", get_an_identity_id: SecureRandom.uuid, full_name: "New Name") }
        let(:user) do
          create(:user, email: ecf_user.email, ecf_id: SecureRandom.uuid, uid: ecf_user.get_an_identity_id, full_name: "Old Name")
        end

        context "when NPQ user.ecf_id is set but no ecf user found" do
          it "updates user.ecf_id with ecf_user.id" do
            expect(Migration::Ecf::User.find_by(id: user.ecf_id)).to be_nil

            instance.call
            expect(user.reload.ecf_id).to eq(ecf_user.id)
            expect(user.full_name).to eq("New Name")
          end
        end

        context "when NPQ user.ecf_id links to a different ecf_user" do
          context "when linked ecf_user is an orphan" do
            it "updates user.ecf_id with ecf_user.id" do
              orphaned_ecf_user = create(:ecf_migration_user, id: user.ecf_id)
              expect(orphaned_ecf_user.npq_applications).to be_empty

              instance.call
              expect(user.reload.ecf_id).to eq(ecf_user.id)
              expect(user.full_name).to eq("New Name")
            end
          end

          context "when linked ecf_user is not an orphan" do
            let(:failure_manager) do
              TmpFailureManager.new
            end

            it "raises error" do
              non_orphaned_ecf_user = create(:ecf_migration_user, :npq, id: user.ecf_id)
              expect(non_orphaned_ecf_user.npq_applications).to be_present

              instance.call
              expect(failure_manager.failures(ecf_user)).to eq("Validation failed: User found with ecf_user.get_an_identity_id, but its user.ecf_id linked to another ecf_user that is not an orphan")
              expect(failure_manager.failures(non_orphaned_ecf_user)).to eq("Validation failed: Participant identity email from ECF does not match existing user email in NPQ")
            end
          end
        end
      end
    end
  end
end
