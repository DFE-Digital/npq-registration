require "rails_helper"

RSpec.feature "reject applications", :rack_test_driver, type: :feature do
  include Helpers::AdminLogin
  include Helpers::BulkOperations

  let(:admin) { create(:admin) }
  let(:filename) { File.basename(applications_file.path) }

  before do
    create :cohort, :current
    create_list(:application, 2, :pending)
  end

  context "when not logged in" do
    scenario "Reject applications page is inaccessible" do
      visit npq_separation_admin_bulk_operations_reject_applications_path
      expect(page).to have_current_path(sign_in_path)
    end
  end

  context "when logged in as admin" do
    before { sign_in_as(admin) }

    scenario "reject applications" do
      visit npq_separation_admin_path
      click_link "Bulk operations"
      click_link "Reject applications"

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

      visit npq_separation_admin_bulk_operations_reject_applications_path
      perform_enqueued_jobs do
        click_button "Reject applications"
      end

      click_link filename
      within(".govuk-summary-list") do |summary_list|
        expect(summary_list).to have_summary_item("Filename", filename)
        expect(summary_list).to have_summary_item("Rows", "2")
        expect(summary_list).to have_summary_item("Created by", "#{admin.full_name} (#{admin.email})")
        expect(summary_list).to have_summary_item("Ran by", "#{admin.full_name} (#{admin.email})")
      end

      expect(page).to have_content "#{Application.first.ecf_id}Changed to rejected"
      expect(page).to have_content "#{Application.last.ecf_id}Changed to rejected"
      expect(page).not_to have_button("Reject applications")
      expect(Application.all.pluck(:lead_provider_approval_status)).to eq %w[rejected rejected]
    end

    scenario "when the bulk operation has started but not finished" do
      visit npq_separation_admin_bulk_operations_reject_applications_path
      attach_file "file", applications_file.path
      click_button "Upload file"
      click_button "Reject applications"
      click_link filename

      expect(page).to have_content "The bulk operation is in progress."
    end

    scenario "file validation" do
      visit npq_separation_admin_bulk_operations_reject_applications_path
      attach_file "file", empty_file.path
      click_button "Upload"
      expect(page).to have_content "is empty"

      attach_file "file", wrong_format_file.path
      click_button "Upload"
      expect(page).to have_content "is wrong format"

      attach_file "file", applications_file.path
      click_button "Upload"
      expect(page).to have_button "Reject applications"
    end
  end
end
