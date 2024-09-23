require "rails_helper"

RSpec.describe Migration::Migrators::User do
  it_behaves_like "a migrator", :user, [] do
    def create_ecf_resource
      travel_to 10.days.ago do
        create(:ecf_migration_user, :npq)
      end
    end

    def create_npq_resource(ecf_resource)
      create(:user, :with_random_name, ecf_id: ecf_resource.id, email: ecf_resource.email)
    end

    def setup_failure_state
      # Duplicate users with ecf_id
      ecf_user = create(:ecf_migration_user, :npq)
      create(:user, ecf_id: ecf_user.id)
      create(:user, ecf_id: ecf_user.id)
    end

    describe "#call" do
      it "sets User attributes with most recent created npq application" do
        travel_to 5.days.ago do
          participant_identity1 = create(:ecf_migration_participant_identity, user: ecf_resource1, email: "email-2@example.com", external_identifier: SecureRandom.uuid)
          create(:ecf_migration_npq_application, teacher_reference_number: ecf_resource1.npq_applications.first.teacher_reference_number, participant_identity: participant_identity1)
        end
        travel_to 1.day.ago do
          participant_identity2 = create(:ecf_migration_participant_identity, user: ecf_resource1, email: "email-3@example.com", external_identifier: SecureRandom.uuid)
          create(:ecf_migration_npq_application,
                 teacher_reference_number: ecf_resource1.npq_applications.first.teacher_reference_number,
                 participant_identity: participant_identity2,
                 date_of_birth: "1980-01-01",
                 nino: "1234567890XYZ",
                 active_alert: true,
                 teacher_reference_number_verified: true)
        end

        instance.call

        user = User.find_by(ecf_id: ecf_resource1.id)
        expect(user).to have_attributes(ecf_resource1.attributes.slice(:trn, :full_name, :get_an_identity_id))
        expect(user).to have_attributes(
          email: "email-3@example.com",
          date_of_birth: "1980-01-01".to_date,
          national_insurance_number: "1234567890XYZ",
          active_alert: true,
          trn_verified: true,
        )
      end

      it "records a failure when there are multiple, different TRNs for the user's NPQApplications in ECF and no teacher profile TRN" do
        ecf_user = create(:ecf_migration_user, :npq).tap { |u| u.teacher_profile.update!(trn: nil) }
        create(:ecf_migration_npq_application, teacher_reference_number: "123456", teacher_reference_number_verified: true, participant_identity: ecf_user.participant_identities.first)
        instance.call
        expect(failure_manager).to have_received(:record_failure).with(ecf_user, /There are multiple different TRNs from NPQ applications/)
      end

      it "does not record a failure when there are multiple, different TRNs for the user's NPQApplications in ECF and there is also a teacher profile TRN" do
        ecf_user = create(:ecf_migration_user, :npq).tap { |u| u.teacher_profile.update!(trn: "1234567") }
        create(:ecf_migration_npq_application, teacher_reference_number: "123456", teacher_reference_number_verified: true, participant_identity: ecf_user.participant_identities.first)
        instance.call
        expect(failure_manager).not_to have_received(:record_failure)
        user = User.find_by(ecf_id: ecf_user.id)
        expect(user.trn).to eq(ecf_user.teacher_profile.trn)
        expect(user).to be_trn_verified
      end

      it "does not record a failure if there are multiple, unverified TRNs for the user's NPQApplications in ECF" do
        ecf_user = create(:ecf_migration_user, :npq)
        create(:ecf_migration_npq_application, teacher_reference_number: "123456", teacher_reference_number_verified: false, participant_identity: ecf_user.participant_identities.first)
        instance.call
        expect(failure_manager).not_to have_received(:record_failure)
        user = User.find_by(ecf_id: ecf_user.id)
        expect(user.trn).to eq(ecf_user.teacher_profile.trn)
        expect(user).to be_trn_verified
      end

      it "retains the NPQ user TRN if the ECF user does not have a verified TRN" do
        ecf_user = create(:ecf_migration_user, :npq).tap do |u|
          u.npq_applications.update!(teacher_reference_number_verified: false)
          u.teacher_profile.update!(trn: nil)
        end
        existing_user = create(:user, ecf_id: ecf_user.id, email: ecf_user.email, trn: "123123", trn_verified: true)
        instance.call
        expect(failure_manager).not_to have_received(:record_failure)
        expect(existing_user.reload).to have_attributes(trn: "123123", trn_verified: true)
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
            let(:records_per_worker) { 10 }

            it "raises error" do
              non_orphaned_ecf_user = create(:ecf_migration_user, :npq, id: user.ecf_id, get_an_identity_id: nil)
              expect(non_orphaned_ecf_user.npq_applications).to be_present

              instance.call
              expect(failure_manager).to have_received(:record_failure).once.with(ecf_user, "Validation failed: User found with ecf_user.get_an_identity_id, but its user.ecf_id linked to another ecf_user that is not an orphan")
            end
          end
        end
      end
    end
  end
end
