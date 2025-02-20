require "rails_helper"

RSpec.describe "one_off:backfill_trn_verified_status", :versioning do
  subject :run_task do
    Rake::Task["one_off:backfill_trn_verified_status"].invoke(dry_run)
  end

  after { Rake::Task["one_off:backfill_trn_verified_status"].reenable }

  let(:user) { create(:user, trn: nil, trn_verified: false) }
  let(:dry_run) { "false" }

  context "with users who were incorrectly marked unverified" do
    before do
      user.trn = "1029384"
      user.trn_verified = true
      user.trn_auto_verified = true
      user.trn_lookup_status = "Found"
      user.save!

      user.update!(trn_verified: false, trn_lookup_status: nil, updated_from_tra_at: Time.zone.now)
    end

    it "updates trn_verified" do
      expect { run_task }.to change { user.reload.trn_verified }.from(false).to(true)
    end

    it "updates trn_lookup_status" do
      expect { run_task }.to change { user.reload.trn_lookup_status }.from(nil).to("Found")
    end

    context "when performing a dry run" do
      let(:dry_run) { "" }

      it "does not update trn_verified" do
        expect { run_task }.not_to(change { user.reload.trn_verified })
      end

      it "does not update trn_lookup_status" do
        expect { run_task }.not_to(change { user.reload.trn_lookup_status })
      end
    end
  end

  context "with users who were never verified" do
    before { user.update!(trn: "1029384", updated_from_tra_at: Time.zone.now) }

    it "does not update trn_verified" do
      expect { run_task }.not_to(change { user.reload.trn_verified })
    end

    it "does not update trn_lookup_status" do
      expect { run_task }.not_to(change { user.reload.trn_lookup_status })
    end
  end

  context "with users whose TRN was also changed" do
    before do
      user.trn = "1029384"
      user.trn_verified = true
      user.trn_auto_verified = true
      user.trn_lookup_status = "Found"
      user.save!

      user.update!(
        trn: "2121212",
        trn_verified: false,
        trn_lookup_status: nil,
        updated_from_tra_at: Time.zone.now,
      )
    end

    it "does not update trn_verified" do
      expect { run_task }.not_to(change { user.reload.trn_verified })
    end

    it "does not update trn_lookup_status" do
      expect { run_task }.not_to(change { user.reload.trn_lookup_status })
    end
  end

  context "with users whose trn_verified status changed but they've never had lookup_status set" do
    before do
      user.trn = "1029384"
      user.trn_verified = true
      user.trn_auto_verified = true
      user.trn_lookup_status = nil
      user.save!

      user.update!(trn_verified: false, trn_lookup_status: nil, updated_from_tra_at: Time.zone.now)
    end

    it "updates trn_verified" do
      expect { run_task }.to change { user.reload.trn_verified }.from(false).to(true)
    end

    it "leaves trn_lookup_status as nil" do
      expect { run_task }.not_to(change { user.reload.trn_lookup_status })
    end
  end
end
