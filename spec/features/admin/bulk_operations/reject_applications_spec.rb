require "rails_helper"

RSpec.feature "reject applications", :rack_test_driver, type: :feature do
  include Helpers::AdminLogin
  include Helpers::BulkOperations

  let(:admin) { create(:admin) }
  let(:filename) { File.basename(applications_file.path) }

  before do
    sign_in_as_admin
    create_list(:application, 2, :pending)
  end

  scenario "reject applications" do
    visit npq_separation_admin_bulk_operations_reject_applications_path
    attach_file "file", applications_file.path
    click_button "Upload"

    click_link filename
    within(".govuk-summary-list") do |summary_list|
      expect(summary_list).to have_summary_item("Filename", filename)
      expect(summary_list).to have_summary_item("Rows", "2")
    end

    visit npq_separation_admin_bulk_operations_reject_applications_path
    perform_enqueued_jobs do
      click_button "Reject Applications"
    end
    click_link filename

    within(".govuk-summary-list") do |summary_list|
      expect(summary_list).to have_summary_item("Filename", filename)
      expect(summary_list).to have_summary_item("Rows", "2")
    end
    expect(page).to have_content "#{Application.first.ecf_id}Changed to rejected"
    expect(page).to have_content "#{Application.last.ecf_id}Changed to rejected"
    expect(page).not_to have_button("Reject Applications")
    expect(Application.all.pluck(:lead_provider_approval_status)).to eq %w[rejected rejected]
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
    expect(page).to have_button "Reject Applications"
  end
end
