require "rails_helper"

RSpec.feature "Changing review status of an application", type: :feature do
  include Helpers::AdminLogin

  let(:application) { create :application, :manual_review }

  it "updates the review status and adds a note" do
    sign_in_as create(:admin)
    visit npq_separation_admin_application_review_path(application)

    within(".govuk-summary-list__row", text: "Review status") do
      assert_text "Needs review"
      click_on "Change"
    end

    choose "Awaiting information", allow_label_click: true
    click_on "Update review status"

    fill_in "Add a note about the changes to this registration", with: "Test note"
    click_on "Add note"

    expect(page).to have_text("Review status updated from 'Needs review' to 'Awaiting information'.")
    expect(page).to have_summary_item("Review status", "Awaiting information")
    expect(page).to have_summary_item("Notes", "Test note")
  end
end
