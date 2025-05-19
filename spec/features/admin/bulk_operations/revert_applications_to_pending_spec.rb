require "rails_helper"

RSpec.feature "revert applications to pending", :rack_test_driver, type: :feature do
  include Helpers::AdminLogin
  include Helpers::BulkOperations

  let(:admin) { create(:admin) }
  let(:filename) { File.basename(applications_file.path) }

  before do
    create :cohort, :current
    create(:application, :accepted)
    create(:application, :accepted)
  end

  context "when not logged in" do
    scenario "Revert applications page is inaccessible" do
      visit npq_separation_admin_bulk_operations_revert_applications_to_pending_index_path
      expect(page).to have_current_path(sign_in_path)
    end
  end

  context "when logged in as admin" do
    before { sign_in_as(admin) }

    scenario "reverting applications to pending" do
      visit npq_separation_admin_path
      click_link "Bulk operations"
      click_link "Revert applications to pending"

      expect(page).to have_content "No files have been uploaded"

      attach_file "file", applications_file.path
      click_button "Upload file"

      expect(page).to have_content "File #{filename} uploaded successfully"

      click_link filename
      within(".govuk-summary-list") do |summary_list|
        expect(summary_list).to have_summary_item("Filename", filename)
        expect(summary_list).to have_summary_item("Rows", "2")
        expect(summary_list).to have_summary_item("Created by", "#{admin.full_name} (#{admin.email})")
      end

      visit npq_separation_admin_bulk_operations_revert_applications_to_pending_index_path
      perform_enqueued_jobs do
        click_button "Revert applications to pending"
      end

      click_link filename
      within(".govuk-summary-list") do |summary_list|
        expect(summary_list).to have_summary_item("Filename", filename)
        expect(summary_list).to have_summary_item("Rows", "2")
        expect(summary_list).to have_summary_item("Created by", "#{admin.full_name} (#{admin.email})")
        expect(summary_list).to have_summary_item("Ran by", "#{admin.full_name} (#{admin.email})")
      end

      expect(page).to have_content "#{Application.first.ecf_id}Changed to pending"
      expect(page).to have_content "#{Application.last.ecf_id}Changed to pending"
      expect(page).not_to have_button("Revert applications to pending")
      expect(Application.all.pluck(:lead_provider_approval_status)).to eq %w[pending pending]
    end

    scenario "when the bulk operation has started but not finished" do
      visit npq_separation_admin_bulk_operations_revert_applications_to_pending_index_path
      attach_file "file", applications_file.path
      click_button "Upload file"
      click_button "Revert applications to pending"
      click_link filename

      expect(page).to have_content "The bulk operation is in progress."
    end

    scenario "file validation" do
      visit npq_separation_admin_bulk_operations_revert_applications_to_pending_index_path
      attach_file "file", empty_file.path
      click_button "Upload"
      expect(page).to have_content "is empty"

      attach_file "file", wrong_format_file.path
      click_button "Upload"
      expect(page).to have_content "is wrong format"

      attach_file "file", applications_file.path
      click_button "Upload"
      expect(page).to have_button "Revert applications to pending"
    end
  end
end
