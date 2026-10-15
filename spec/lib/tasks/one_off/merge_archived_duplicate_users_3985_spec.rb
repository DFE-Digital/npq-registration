# frozen_string_literal: true

require "rails_helper"

RSpec.describe "one_off:merge_archived_duplicate_users" do
  subject(:run_task) { Rake::Task["one_off:merge_archived_duplicate_users"].invoke(dry_run) }

  after { Rake::Task["one_off:merge_archived_duplicate_users"].reenable }

  let(:dry_run) { "false" }
  let(:trn) { "1234567" }
  let(:archived_user) { create(:user, :archived, :with_verified_trn, trn:, email: nil) }
  let!(:application) { create(:application, :accepted, user: archived_user) }
  let!(:user_to_keep) { create(:user, :with_teacher_auth, :with_verified_trn, trn:) }

  it "moves the applications to the not archived user with the same TRN" do
    run_task
    expect(application.reload.user).to eq user_to_keep
  end

  it "creates a participant ID change from the archived user to the kept user" do
    run_task
    expect(user_to_keep.participant_id_changes.first).to have_attributes(from_participant_id: archived_user.ecf_id, to_participant_id: user_to_keep.ecf_id)
  end

  it "keeps the archived user archived" do
    expect { run_task }.not_to(change { archived_user.reload.archived_at })
  end

  context "when it is a dry run" do
    let(:dry_run) { nil }

    it "does not move the applications" do
      run_task
      expect(application.reload.user).to eq archived_user
    end

    it "does not create a participant ID change" do
      expect { run_task }.not_to change(ParticipantIdChange, :count)
    end
  end

  context "when there is no not archived TeacherAuth user with the same TRN" do
    let!(:user_to_keep) { create(:user, :with_teacher_auth, :with_verified_trn, trn: "7654321") }

    it "does not move the applications" do
      run_task
      expect(application.reload.user).to eq archived_user
    end
  end

  context "when the not archived TeacherAuth user with the same TRN is not verified" do
    let!(:user_to_keep) { create(:user, :with_teacher_auth, trn:, trn_verified: false) }

    it "does not move the applications" do
      run_task
      expect(application.reload.user).to eq archived_user
    end
  end

  context "when there is more than one not archived TeacherAuth user with the same TRN" do
    before { create(:user, :with_teacher_auth, :with_verified_trn, trn:) }

    it "does not move the applications" do
      run_task
      expect(application.reload.user).to eq archived_user
    end
  end

  context "when the not archived user with the same TRN is not a TeacherAuth user" do
    let!(:user_to_keep) { create(:user, :with_get_an_identity_id, :with_verified_trn, trn:) }

    it "does not move the applications" do
      run_task
      expect(application.reload.user).to eq archived_user
    end
  end

  context "when the archived user has no applications" do
    let!(:application) { nil }

    it "does not create a participant ID change" do
      expect { run_task }.not_to change(ParticipantIdChange, :count)
    end
  end

  context "when the archived user still has an email" do
    let(:archived_user) { create(:user, :archived, :with_verified_trn, trn:) }

    it "does not move the applications" do
      run_task
      expect(application.reload.user).to eq archived_user
    end
  end
end
