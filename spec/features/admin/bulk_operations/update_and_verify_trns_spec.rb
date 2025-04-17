require "rails_helper"

RSpec.feature "update and verify TRNs", :rack_test_driver, type: :feature do
  include Helpers::AdminLogin
  include Helpers::BulkOperations

  let(:admin) { create(:admin) }

  let(:trns_file) do
    Tempfile.new.tap do |file|
      file.write "User ID,Updated TRN\n"
      file.write "#{User.first.ecf_id},1234567\n"
      file.write "#{User.last.ecf_id},2345678\n"
      file.rewind
    end
  end

  before do
    sign_in_as_admin
    create(:user)
    create(:user)
  end

  scenario "updating and verifying TRNs" do
    visit npq_separation_admin_bulk_operations_update_and_verify_trns_path
    attach_file "file", trns_file.path
    click_button "Upload file"
    perform_enqueued_jobs do
      click_button "Update and verify TRNs"
    end
    click_link File.basename(trns_file.path)
    # expect(page).to have_content "#{User.first.ecf_id}updated"
    # expect(page).to have_content "#{User.last.ecf_id}updated"
    expect(page).not_to have_button("Update and verify TRNs")
    # expect(User.all.pluck(:trn)).to eq %w[1234567 2345678]
  end

  scenario "file validation" do
    visit npq_separation_admin_bulk_operations_update_and_verify_trns_path
    attach_file "file", empty_file.path
    click_button "Upload"
    expect(page).to have_content "is empty"

    attach_file "file", wrong_format_file.path
    click_button "Upload"
    expect(page).to have_content "is wrong format"

    attach_file "file", trns_file.path
    click_button "Upload"
    expect(page).to have_button "Update and verify TRNs"
  end
end
