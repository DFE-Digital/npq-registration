require "rails_helper"

RSpec.feature "revert applications to pending", :rack_test_driver, type: :feature do
  include Helpers::AdminLogin
  include Helpers::BulkOperations
  include_context "Stub Get An Identity Omniauth Responses"

  let(:admin) { create(:admin) }

  before do
    sign_in_as_admin
    create(:application, :accepted)
    create(:application, :accepted)
  end

  scenario "reverting applications to pending" do
    visit npq_separation_admin_bulk_operations_revert_applications_to_pending_index_path
    attach_file "file", applications_file.path
    click_button "Upload"
    perform_enqueued_jobs do
      click_button "Revert Applications to Pending"
    end
    click_link File.basename(applications_file.path)
    expect(page).to have_content "#{Application.first.ecf_id}Changed to pending"
    expect(page).to have_content "#{Application.last.ecf_id}Changed to pending"
    expect(page).not_to have_button("Revert Applications to Pending")
    expect(Application.all.pluck(:lead_provider_approval_status)).to eq %w[pending pending]
  end

  scenario "file validation" do
    visit npq_separation_admin_bulk_operations_revert_applications_to_pending_index_path
    attach_file "file", empty_applications_file.path
    click_button "Upload"
    expect(page).to have_content "is empty"

    attach_file "file", wrong_format_file.path
    click_button "Upload"
    expect(page).to have_content "is wrong format"

    attach_file "file", applications_file.path
    click_button "Upload"
    expect(page).to have_button "Revert Applications to Pending"
  end
end
