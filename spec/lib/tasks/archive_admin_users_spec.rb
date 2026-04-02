require "rails_helper"

RSpec.describe "Archive admin user task" do
  subject(:run_task) { Rake::Task["archive_admin_users"].invoke(csv_file_path, dry_run) }

  let(:admin_user_to_archive) { create(:admin) }
  let(:super_admin_user_to_archive) { create(:super_admin) }
  let(:admin_user_not_to_archive) { create(:admin) }
  let(:super_admin_user_not_to_archive) { create(:super_admin) }
  let(:csv_file_path) { csv_file.path }

  let(:csv_file) do
    tempfile <<~CSV
      #{admin_user_to_archive.email}
      #{super_admin_user_to_archive.email}
    CSV
  end

  before do
    admin_user_not_to_archive
    super_admin_user_not_to_archive
    csv_file
  end

  after do
    Rake::Task["archive_admin_users"].reenable
  end

  context "when dry run is false" do
    let(:dry_run) { "false" }

    it "archives the specified admin users" do
      run_task
      expect(admin_user_to_archive.reload.archived_at).to be_present
      expect(super_admin_user_to_archive.reload.archived_at).to be_present
    end

    it "does not archive admin users not specified in the CSV" do
      expect(admin_user_not_to_archive.reload.archived_at).to be_nil
      expect(super_admin_user_not_to_archive.reload.archived_at).to be_nil
    end
  end

  context "when dry run is true" do
    let(:dry_run) { nil }

    it "does not archive any admin users" do
      run_task
      expect(admin_user_to_archive.reload.archived_at).to be_nil
      expect(super_admin_user_to_archive.reload.archived_at).to be_nil
      expect(admin_user_not_to_archive.reload.archived_at).to be_nil
      expect(super_admin_user_not_to_archive.reload.archived_at).to be_nil
    end
  end
end
