require "rails_helper"

RSpec.feature "Reopening Email Subscription Management", type: :feature, rack_test_driver: true do
  include Helpers::AdminLogin

  let(:super_admin) { create(:super_admin) }

  before do
    sign_in_as(super_admin)
    create :user, email_updates_status: :senco, email: "example@example.org", full_name: "John Doe"
  end

  scenario "unsubscribe user" do
    click_link "Reopening email subscriptions"
    expect(page).to have_text("example@example.org")
    click_link "Unsubscribe"
    click_link "Unsubscribe"
    expect(page).to have_text("Email 'example@example.org' unsubscribed")
  end

  scenario "when logged in as a regular admin, it allows access to the admin homepage" do
    click_link "Reopening email subscriptions"
    click_link "Export all with SENCO interest"
    expect(page.body).to eq("Name,Email\n  John Doe,example@example.org\n")
  end
end
