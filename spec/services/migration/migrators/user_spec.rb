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
        expect_any_instance_of(Migration::FailureManager).to receive(:record_failure).with(ecf_migration_user, "PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint \"index_users_on_uid\"\nDETAIL:  Key (uid)=(123456) already exists.\n").and_call_original

        subject
      end
    end
  end
end
