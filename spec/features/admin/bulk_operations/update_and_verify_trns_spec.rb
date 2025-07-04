require "rails_helper"

RSpec.feature "update and verify TRNs", :rack_test_driver, type: :feature do
  include Helpers::AdminLogin
  include Helpers::BulkOperations

  let(:admin) { create(:admin) }
  let(:filename) { File.basename(trns_file.path) }

  let(:trns_file) do
    tempfile <<~CSV
      User ID,Updated TRN
      #{User.order(:id).first.ecf_id},1234567
      #{User.order(:id).last.ecf_id},2345678
    CSV
  end

  let(:only_headers_trns_file) do
    tempfile <<~CSV
      User ID,Updated TRN
    CSV
  end

  let(:no_headers_trns_file) do
    tempfile <<~CSV
      #{User.order(:id).first.ecf_id},1234567
      #{User.order(:id).last.ecf_id},2345678
    CSV
  end

  let(:wrong_format_trns_file) do
    tempfile <<~CSV
      User ID
      #{User.order(:id).first.ecf_id}
      #{User.order(:id).last.ecf_id}
    CSV
  end

  before do
    create :cohort, :current
    create(:user)
    create(:user)
  end

  context "when not logged in" do
    scenario "bulk operations index page is inaccessible" do
      visit npq_separation_admin_bulk_operations_path
      expect(page).to have_current_path(sign_in_path)
    end

    scenario "update and verify TRNs page is inaccessible" do
      visit npq_separation_admin_bulk_operations_update_and_verify_trns_path
      expect(page).to have_current_path(sign_in_path)
    end
  end

  context "when logged in as admin" do
    before { sign_in_as(admin) }

    scenario "updating and verifying TRNs" do
      visit npq_separation_admin_path
      click_link "Bulk changes"
      click_link "Update and verify TRNs"

      expect(page).to have_content "No files have been uploaded"

      attach_file "file", trns_file.path
      click_button "Upload file"

      expect(page).to have_content "File #{filename} uploaded successfully"

      click_link filename
      within(".govuk-summary-list") do |summary_list|
        expect(summary_list).to have_summary_item("Filename", filename)
        expect(summary_list).to have_summary_item("Rows", "2")
        expect(summary_list).to have_summary_item("Created by", "#{admin.full_name} (#{admin.email})")
      end

      visit npq_separation_admin_bulk_operations_update_and_verify_trns_path
      perform_enqueued_jobs do
        click_button "Update and verify TRNs"
      end

      click_link filename
      within(".govuk-summary-list") do |summary_list|
        expect(summary_list).to have_summary_item("Filename", filename)
        expect(summary_list).to have_summary_item("Rows", "2")
        expect(summary_list).to have_summary_item("Created by", "#{admin.full_name} (#{admin.email})")
        expect(summary_list).to have_summary_item("Ran by", "#{admin.full_name} (#{admin.email})")
      end

      expect(page).to have_content "#{User.order(:id).first.ecf_id}TRN updated and verified"
      expect(page).to have_content "#{User.order(:id).last.ecf_id}TRN updated and verified"
      expect(page).not_to have_button("Update and verify TRNs")
      expect(User.all.pluck(:trn)).to match_array %w[1234567 2345678]
      expect(User.all).to all be_trn_verified
    end

    scenario "when the bulk operation has started but not finished" do
      visit npq_separation_admin_bulk_operations_update_and_verify_trns_path
      attach_file "file", trns_file.path
      click_button "Upload file"
      click_button "Update and verify TRNs"
      click_link filename

      expect(page).to have_content "The bulk operation is in progress."
    end

    scenario "file validation" do
      visit npq_separation_admin_bulk_operations_update_and_verify_trns_path
      attach_file "file", empty_file.path
      click_button "Upload"
      expect(page).to have_content "is empty"

      visit npq_separation_admin_bulk_operations_update_and_verify_trns_path
      attach_file "file", only_headers_trns_file.path
      click_button "Upload"
      expect(page).to have_content "is empty"

      attach_file "file", wrong_format_trns_file.path
      click_button "Upload"
      expect(page).to have_content "is wrong format"

      attach_file "file", no_headers_trns_file.path
      click_button "Upload"
      expect(page).to have_content "is wrong format"

      attach_file "file", trns_file.path
      click_button "Upload"
      expect(page).to have_button "Update and verify TRNs"
    end
  end
end
