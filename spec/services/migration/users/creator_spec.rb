require "rails_helper"

RSpec.describe Migration::Users::Creator do
  let(:ecf_user) { create(:ecf_migration_user, :npq, get_an_identity_id: SecureRandom.uuid, email: "email-1@example.com") }
  let(:ecf_user_email) { nil }

  subject { described_class.new(ecf_user, ecf_user_email) }

  describe ".find_or_initialize" do
    context "when ecf_user_email user does not exist" do
      let(:ecf_user_email) { nil }

      context "when find_primary_user returns nil" do
        it "returns new user" do
          expect(User.find_by(ecf_id: ecf_user.id)).to be_nil
          expect(User.find_by(uid: ecf_user.get_an_identity_id)).to be_nil

          user = subject.find_or_initialize

          expect(user).to be_new_record
          expect(user.ecf_id).to eq(ecf_user.id)
        end
      end

      context "when find_primary_user returns user" do
        it "returns primary user" do
          existing_user = create(:user, ecf_id: ecf_user.id, uid: ecf_user.get_an_identity_id)

          user = subject.find_or_initialize

          expect(user).to eq(existing_user)
          expect(user.ecf_id).to eq(ecf_user.id)
          expect(user.uid).to eq(ecf_user.get_an_identity_id)
        end
      end
    end

    context "when ecf_user_email user exists" do
      context "when email is same as primary user" do
        let(:existing_user) { create(:user, ecf_id: ecf_user.id, uid: ecf_user.get_an_identity_id) }
        let(:ecf_user_email) { existing_user.email }

        it "returns primary user" do
          user = subject.find_or_initialize

          expect(user).to eq(existing_user)
          expect(user.ecf_id).to eq(ecf_user.id)
          expect(user.uid).to eq(ecf_user.get_an_identity_id)
          expect(user.email).to eq(ecf_user_email)
        end
      end

      context "when find_primary_user is nil" do
        let(:existing_email_user) { create(:user, ecf_id: SecureRandom.uuid) }
        let(:ecf_user_email) { existing_email_user.email }

        it "returns email user with ecf_id set to ecf_user.id" do
          expect(existing_email_user.ecf_id).not_to eq(ecf_user.id)

          user = subject.find_or_initialize

          expect(user).to eq(existing_email_user)
          expect(user.ecf_id).to eq(ecf_user.id)
          expect(user.email).to eq(ecf_user_email)
        end
      end
    end
  end

  describe ".find_primary_user" do
    let(:ecf_user_email) { nil }

    context "when user doesnt exist" do
      it "returns nil" do
        expect(User.find_by(ecf_id: ecf_user.id)).to be_nil
        expect(User.find_by(uid: ecf_user.get_an_identity_id)).to be_nil

        user = subject.find_primary_user

        expect(user).to be_nil
      end
    end

    context "when multiple users have same ecf_user.id" do
      it "raises error" do
        create(:user, ecf_id: ecf_user.id)
        create(:user, ecf_id: ecf_user.id)

        expect {
          subject.find_primary_user
        }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: ecf_user.id has multiple users in NPQ")
      end
    end

    context "when ecf_user.id and ecf_user.get_an_identity_id return the same user" do
      it "returns user" do
        existing_user = create(:user, ecf_id: ecf_user.id, uid: ecf_user.get_an_identity_id)

        user = subject.find_primary_user

        expect(user).to eq(existing_user)
        expect(user.ecf_id).to eq(ecf_user.id)
        expect(user.uid).to eq(ecf_user.get_an_identity_id)
      end
    end

    context "when user with only ecf_user.id exist" do
      it "returns user" do
        existing_user = create(:user, ecf_id: ecf_user.id, uid: nil)

        user = subject.find_primary_user

        expect(user).to eq(existing_user)
        expect(user.ecf_id).to eq(ecf_user.id)
      end
    end

    context "when ecf_user.id and ecf_user.get_an_identity_id return different users" do
      let!(:existing_user1) { create(:user, ecf_id: ecf_user.id, email: ecf_user.email) }
      let!(:existing_user2) { create(:user, uid: ecf_user.get_an_identity_id, ecf_id: SecureRandom.uuid, email: "email-2@example.com") }

      context "when user.uid links to non-existing ecf_user" do
        it "returns user with updated ecf_id merges user" do
          expect(::Migration::Ecf::User.find_by(id: existing_user2.ecf_id)).to be_nil

          user = subject.find_primary_user

          expect(user.reload).to eq(existing_user1)
          expect(user.ecf_id).to eq(ecf_user.id)

          expect(existing_user2.reload.uid).to be_nil
        end
      end

      context "when user.uid links to orphaned ecf_user" do
        let(:orphaned_ecf_user) { create(:ecf_migration_user, id: existing_user2.ecf_id, email: "email-2@example.com") }

        it "returns user with updated ecf_id merges user" do
          orphaned_ecf_user
          expect(::Migration::Ecf::User.find_by(id: existing_user2.ecf_id)).to eq(orphaned_ecf_user)

          user = subject.find_primary_user

          expect(user.reload).to eq(existing_user1)
          expect(user.ecf_id).to eq(ecf_user.id)

          expect(existing_user2.reload.uid).to be_nil
        end
      end

      context "when user.uid links to non-orphaned ecf_user" do
        let(:non_orphaned_ecf_user) { create(:ecf_migration_user, :npq, id: existing_user2.ecf_id, email: existing_user2.email) }

        it "raises error" do
          non_orphaned_ecf_user

          expect {
            subject.find_primary_user
          }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: ecf_user.id and ecf_user.get_an_identity_id both return NPQ User records, and the NPQ User link to non-orphan ECF users")
        end
      end
    end

    context "when user with only ecf_user.get_an_identity_id exist" do
      let!(:existing_user) { create(:user, uid: ecf_user.get_an_identity_id, ecf_id: SecureRandom.uuid, email: "email-1@example.com") }

      context "when gai user.ecf_id links to non-existing ecf_user" do
        it "returns user with updated ecf_id" do
          expect(::Migration::Ecf::User.find_by(id: existing_user.ecf_id)).to be_nil

          user = subject.find_primary_user

          expect(user).to eq(existing_user)
          expect(user.ecf_id).to eq(ecf_user.id)
          expect(user.uid).to eq(ecf_user.get_an_identity_id)
        end
      end

      context "when gai user.ecf_id links to orphaned ecf_user" do
        let(:orphaned_ecf_user) { create(:ecf_migration_user, id: existing_user.ecf_id, email: "email-2@example.com") }

        it "returns user with updated ecf_id" do
          orphaned_ecf_user
          expect(::Migration::Ecf::User.find_by(id: existing_user.ecf_id)).to eq(orphaned_ecf_user)

          user = subject.find_primary_user

          expect(user).to eq(existing_user)
          expect(user.ecf_id).to eq(ecf_user.id)
          expect(user.uid).to eq(ecf_user.get_an_identity_id)
        end
      end

      context "when gai user.ecf_id links to non-orphaned ecf_user" do
        let(:non_orphaned_ecf_user) { create(:ecf_migration_user, :npq, id: existing_user.ecf_id, email: "email-2@example.com") }

        it "raises error" do
          non_orphaned_ecf_user

          expect {
            subject.find_primary_user
          }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: User found with ecf_user.get_an_identity_id, but its user.ecf_id linked to another ecf_user that is not an orphan")
        end
      end
    end
  end
end
