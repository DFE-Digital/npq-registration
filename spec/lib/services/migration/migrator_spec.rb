require "rails_helper"

RSpec.describe Migration::Migrator do
  let(:instance) { described_class.new }

  describe "#migrate!" do
    subject(:migrate) { instance.migrate! }

    it { expect { migrate }.to change(Migration::Result, :count).by(1) }

    context "when creating a migration result" do
      it "writes a Migration::Result containing details of the users migration" do
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

        migration_result = Migration::Result.last

        expect(migration_result).to have_attributes({
          users_count: 6,
          orphaned_ecf_users_count: 1,
          orphaned_npq_users_count: 2,
          duplicate_users_count: 1,
          matched_users_count: 2,
        })
      end

      it "writes a Migration::Result containing details of the applications migration" do
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

        expect { instance.migrate! }.to change(Migration::Result, :count).by(1)

        migration_result = Migration::Result.last

        expect(migration_result).to have_attributes({
          applications_count: 6,
          orphaned_ecf_applications_count: 2,
          orphaned_npq_applications_count: 1,
          duplicate_applications_count: 1,
          matched_applications_count: 2,
        })
      end
    end
  end
end
