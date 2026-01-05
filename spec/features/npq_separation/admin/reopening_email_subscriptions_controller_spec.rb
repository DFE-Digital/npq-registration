require "rails_helper"

RSpec.feature "Reopening Email Subscription Management", :rack_test_driver, type: :feature do
  include Helpers::AdminLogin

  let(:super_admin) { create(:super_admin) }

  before do
    sign_in_as(super_admin)
    create(:cohort, registration_start_date: 1.year.ago, start_year: 1.year.ago.year)
    create :user, email_updates_status: :senco, email: "example@example.org", full_name: "John Doe"
  end

  scenario "unsubscribe user" do
    visit("/npq-separation/admin")
    click_link "Registration closed"
    click_link "Users who’ve requested emails about registration reopening"
    expect(page).to have_text("example@example.org")
    click_link "Unsubscribe"
    click_link "Unsubscribe"
    expect(page).to have_text("Email 'example@example.org' unsubscribed")
  end

  scenario "super admin exports users with SENCO interest as CSV" do
    visit("/npq-separation/admin")
    click_link "Registration closed"
    click_link "Users who’ve requested emails about registration reopening"
    click_link "Export all with SENCO interest"
    expect(page.body).to eq("Name,Email\n  John Doe,example@example.org\n")
  end
end
