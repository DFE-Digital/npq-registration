require "rails_helper"

RSpec.describe Migration::Migrator, in_memory_rails_cache: true do
  let(:instance) { described_class.new }

  describe ".prepare_for_migration!" do
    subject(:prepare) { described_class.prepare_for_migration! }

    context "when there is no migration in progress" do
      it { expect { prepare }.to change(Migration::Result, :count).by(1) }
    end

    context "when there is a migration in progress" do
      before { create(:migration_result, :incomplete) }

      it { expect { prepare }.to raise_error(described_class::MigrationInProgressError) }
    end
  end

  describe "#migrate!" do
    subject(:migrate) { instance.migrate! }

    before { described_class.prepare_for_migration! }

    context "when the migration has not been prepared" do
      before { Migration::Result.destroy_all }

      it { expect { migrate }.to raise_error(described_class::NoMigrationInProgressError) }
    end

    it "sets the completed_at timestamp on the result" do
      migrate
      result = Migration::Result.most_recent_complete
      expect(result.completed_at).to be_present
    end

    it "writes details of the users reconciliation to the result" do
      # Matched (2)
      ecf_user1 = create(:ecf_user, :teacher, :with_application)
      create(:user, trn: ecf_user1.trn)

      ecf_user2 = create(:ecf_user, :teacher, :with_application)
      create(:user, trn: ecf_user2.trn)

      # Orphaned (1 ECF, 2 NPQ)
      create(:ecf_user, :teacher, :with_application)
      create(:user, trn: "1213443")
      create(:user, trn: "3435675")

      # Duplicated (1)
      ecf_user_3 = create(:ecf_user, :teacher, :with_application)
      create(:user, trn: ecf_user_3.trn)
      create(:user, trn: ecf_user_3.trn)

      migrate
      result = Migration::Result.most_recent_complete

      expect(result).to have_attributes({
        users_count: 6,
        orphaned_ecf_users_count: 1,
        orphaned_npq_users_count: 2,
        duplicate_users_count: 1,
        matched_users_count: 2,
      })
    end

    it "writes details of the applications reconciliation to the result" do
      # Matched (2)
      ecf_application1 = create(:ecf_npq_application)
      create(:application, ecf_id: ecf_application1.id)

      ecf_application2 = create(:ecf_npq_application)
      create(:application, ecf_id: ecf_application2.id)

      # Orphaned (2 ECF, 1 NPQ)
      create(:ecf_npq_application)
      create(:ecf_npq_application)
      create(:application)

      # Duplicated (1)
      ecf_application3 = create(:ecf_npq_application)
      create(:application, ecf_id: ecf_application3.id)
      create(:application, ecf_id: ecf_application3.id)

      migrate
      result = Migration::Result.most_recent_complete

      expect(result).to have_attributes({
        applications_count: 6,
        orphaned_ecf_applications_count: 2,
        orphaned_npq_applications_count: 1,
        duplicate_applications_count: 1,
        matched_applications_count: 2,
      })
    end

    it "caches the orphaned users report" do
      # Orphaned (1 ECF, 2 NPQ)
      ecf_orphan = create(:ecf_user, :teacher, :with_application)
      npq_orphan1 = create(:user, trn: "1213443")
      npq_orphan2 = create(:user, trn: "3435675")

      migrate
      result = Migration::Result.most_recent_complete
      yaml = YAML.load(Rails.cache.read("orphaned_users_#{result.id}"))
      ids = yaml.map { |y| y.dig(:orphan, :id) }

      expect(ids).to contain_exactly(npq_orphan1.id.to_s, npq_orphan2.id.to_s, ecf_orphan.id)
    end

    it "caches the orphaned applications report" do
      # Orphaned (1 ECF, 1 NPQ)
      ecf_orphan = create(:ecf_npq_application)
      npq_orphan = create(:application)

      migrate

      result = Migration::Result.most_recent_complete
      yaml = YAML.load(Rails.cache.read("orphaned_applications_#{result.id}"))
      ids = yaml.map { |y| y.dig(:orphan, :id) }

      expect(ids).to contain_exactly(npq_orphan.id.to_s, ecf_orphan.id)
    end

    it "updates the lead provider approval status of the matched applications" do
      ecf_application = create(:ecf_npq_application, lead_provider_approval_status: "accepted")
      npq_application = create(:application, ecf_id: ecf_application.id, lead_provider_approval_status: "pending")

      expect { migrate }.to change { npq_application.reload.lead_provider_approval_status }.to(ecf_application.lead_provider_approval_status)
    end
  end
end
