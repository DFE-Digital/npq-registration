require "rails_helper"

RSpec.feature "reject applications", :rack_test_driver, type: :feature do
  include Helpers::AdminLogin
  include_context "Stub Get An Identity Omniauth Responses"

  let(:admin) { create(:admin) }

  before do
    sign_in_as_admin
    create(:application, :pending)
    create(:application, :pending)
  end

  scenario "reject applications" do
    visit npq_separation_admin_bulk_operations_reject_applications_path
    attach_file "file", applications_file.path
    click_button "Upload"
    perform_enqueued_jobs do
      click_button "Reject Applications"
    end
    click_link File.basename(applications_file.path)
    expect(page).to have_content "#{Application.first.ecf_id}Changed to rejected"
    expect(page).to have_content "#{Application.last.ecf_id}Changed to rejected"
    expect(page).not_to have_button("Reject Applications")
    expect(Application.all.pluck(:lead_provider_approval_status)).to eq %w[rejected rejected]
  end

  def applications_file
    return @applications_file if @applications_file

    @applications_file = Tempfile.new.tap do |file|
      Application.find_each do |application|
        file.write "#{application.ecf_id}\n"
      end
      file.rewind
    end
  end
end
