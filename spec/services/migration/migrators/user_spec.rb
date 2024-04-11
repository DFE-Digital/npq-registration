require "rails_helper"

RSpec.describe Migration::Migrators::User do
  let(:instance) { described_class.new }

  subject { instance.call }

  describe "#call" do
    before do
      ecf_user1 = create(:ecf_migration_user, :npq)
      ecf_user2 = create(:ecf_migration_user, :npq)

      create(:user, :with_random_name, ecf_id: ecf_user1.id)
      create(:user, :with_random_name, ecf_id: ecf_user2.id)

      create(:data_migration, model: :user)
    end

    it "migrates the users" do
      subject

      expect(Migration::DataMigration.find_by(model: :user).processed_count).to eq(2)
    end

    context "when a user is not correctly created" do
      let!(:ecf_migration_user) { create(:ecf_migration_user, :npq, get_an_identity_id: "123456") }

      before do
        create(:user, :with_random_name, uid: "123456")
      end

      it "increments the failure count " do
        subject

        expect(Migration::DataMigration.find_by(model: :user).processed_count).to eq(3)
        expect(Migration::DataMigration.find_by(model: :user).failure_count).to eq(1)
      end

      it "calls FailureManager with correct params" do
        expect_any_instance_of(Migration::FailureManager).to receive(:record_failure).with(ecf_migration_user, "Validation failed: Uid has already been taken").and_call_original

        subject
      end
    end

    context "when there are multiple TRNs from NPQ applications" do
      let!(:ecf_migration_user) { create(:ecf_migration_user, :npq) }

      before do
        create(:ecf_migration_npq_application, teacher_reference_number: "123456", participant_identity: ecf_migration_user.participant_identities.first)
      end

      it "increments the failure count " do
        subject

        expect(Migration::DataMigration.find_by(model: :user).processed_count).to eq(3)
        expect(Migration::DataMigration.find_by(model: :user).failure_count).to eq(1)
      end

      it "calls FailureManager with correct params" do
        expect_any_instance_of(Migration::FailureManager).to receive(:record_failure).with(ecf_migration_user, "Validation failed: There are multiple different TRNs from NPQ applications").and_call_original

        subject
      end
    end
  end
end
