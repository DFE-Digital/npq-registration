require "rails_helper"

RSpec.describe "merge_user_into_another" do
  let(:merge_and_archive_service) { service_double }
  let(:user_to_merge) { create(:user, :with_get_an_identity_id) }
  let(:user_to_keep) { create(:user) }
  let(:service_double) { instance_double(Users::MergeAndArchive) }

  before { allow(Users::MergeAndArchive).to receive(:new).with(user_to_merge:, user_to_keep:, set_uid: true, logger: an_instance_of(Logger)) { merge_and_archive_service } }
  after { Rake::Task["merge_user_into_another"].reenable }

  subject(:run_task) { Rake::Task["merge_user_into_another"].invoke(user_to_merge.ecf_id, user_to_keep.ecf_id, dry_run) }

  it_behaves_like "passing dry_run to the service"

  context "when the user to merge does not exist" do
    subject(:run_task) { Rake::Task["merge_user_into_another"].invoke(SecureRandom.uuid, user_to_keep.ecf_id, "false") }

    it_behaves_like "exiting with error code 1"
  end

  context "when the user to keep does not exist" do
    subject(:run_task) { Rake::Task["merge_user_into_another"].invoke(user_to_merge.ecf_id, SecureRandom.uuid, "false") }

    it_behaves_like "exiting with error code 1"
  end
end
