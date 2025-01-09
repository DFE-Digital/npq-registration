require "rails_helper"

Rails.application.load_tasks

RSpec.describe "one_off:merge_user_into_another" do
  let!(:user_to_keep_rejected_application) { create(:application, :rejected, user: user_to_keep) }
  let!(:user_to_keep_accepted_application) { create(:application, :accepted, user: user_to_keep) }
  let!(:user_to_merge_pending_application) { create(:application, :pending, user: user_to_merge) }
  let!(:user_to_merge_accepted_application) { create(:application, :accepted, user: user_to_merge) }
  let!(:existing_participant_id_change) { create(:participant_id_change, user: user_to_merge) }
  let(:user_to_merge) { create(:user, :with_get_an_identity_id) }
  let(:user_to_keep) { create(:user) }

  after do
    Rake::Task["one_off:merge_user_into_another"].reenable
  end

  context "when dry run false" do
    subject(:run_task) { Rake::Task["one_off:merge_user_into_another"].invoke(user_to_merge.ecf_id, user_to_keep.ecf_id, "false") }

    shared_examples "merging a user" do
      before { run_task }

      it "archives the user to merge" do
        expect(user_to_merge.reload).to be_archived
      end

      it "keeps the user to keep" do
        expect(user_to_keep).not_to be_archived
      end

      it "moves all applications from the user to merge to the user to keep" do
        expect(user_to_keep.applications).to contain_exactly(user_to_keep_rejected_application,
                                                             user_to_keep_accepted_application,
                                                             user_to_merge_pending_application,
                                                             user_to_merge_accepted_application)
      end

      it "moves existing participant id changes" do
        expect(existing_participant_id_change.reload.user).to eq user_to_keep
      end

      it "creates a participant id change" do
        expect(user_to_keep.participant_id_changes.first).to have_attributes(from_participant_id: user_to_merge.ecf_id, to_participant_id: user_to_keep.ecf_id)
      end
    end

    context "when both users have uids" do
      let(:user_to_keep) { create(:user, :with_get_an_identity_id) }

      it_behaves_like "merging a user"

      it "keeps the user to keep uid" do
        expect { run_task }.not_to change(user_to_keep, :uid)
      end
    end

    context "when only the user to merge as a uid" do
      it_behaves_like "merging a user"

      it "sets the uid to the one from the user to merge" do
        expect { run_task }.to change { user_to_keep.reload.uid }.to(user_to_merge.uid)
      end
    end
  end

  context "when dry run true" do
    subject(:run_task) { Rake::Task["one_off:merge_user_into_another"].invoke(user_to_merge.ecf_id, user_to_keep.ecf_id, "true") }

    it "does not change any users" do
      expect { run_task }.not_to(change { User.all.pluck(:archived_at) })
    end

    it "does not change any applications" do
      expect { run_task }.not_to(change { Application.all.pluck(:user_id) })
    end
  end

  context "when dry run not specified" do
    subject(:run_task) { Rake::Task["one_off:merge_user_into_another"].invoke(user_to_merge.ecf_id, user_to_keep.ecf_id) }

    it "does not change any users" do
      expect { run_task }.not_to(change { User.all.pluck(:archived_at) })
    end

    it "does not change any applications" do
      expect { run_task }.not_to(change { Application.all.pluck(:user_id) })
    end
  end

  context "when the user to merge does not exist" do
    subject(:run_task) { Rake::Task["one_off:merge_user_into_another"].invoke(SecureRandom.uuid, user_to_keep.ecf_id, "false") }

    it_behaves_like "exiting with error code 1"
  end

  context "when the user to keep does not exist" do
    subject(:run_task) { Rake::Task["one_off:merge_user_into_another"].invoke(user_to_merge.ecf_id, SecureRandom.uuid, "false") }

    it_behaves_like "exiting with error code 1"
  end
end
