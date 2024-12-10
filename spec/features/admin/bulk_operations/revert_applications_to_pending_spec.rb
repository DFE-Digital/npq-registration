require "rails_helper"

RSpec.feature "revert applications to pending", :rack_test_driver, type: :feature do
  include Helpers::AdminLogin
  include_context "Stub Get An Identity Omniauth Responses"

  let(:admin) { create(:admin) }

  before do
    Flipper.enable(Feature::ECF_API_DISABLED)
    sign_in_as_admin
    create(:application, :accepted)
    create(:application, :accepted)
  end

  scenario "reverting applications to pending" do
    visit npq_separation_admin_bulk_operations_revert_applications_to_pending_path
    attach_file "file", applications_file.path
    click_button "Upload"
    click_button "Revert Applications to Pending"
    expect(page).to have_content %({"#{Application.first.ecf_id}"=>"Changed to pending", "#{Application.last.ecf_id}"=>"Changed to pending"})
    expect(page).not_to have_button("Revert Applications to Pending")
    expect(Application.all.pluck(:lead_provider_approval_status)).to eq %w[pending pending]
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
