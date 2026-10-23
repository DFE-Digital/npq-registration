require "rails_helper"

RSpec.feature "Reopening Email Subscription Management", :rack_test_driver, type: :feature do
  include Helpers::AdminLogin

  let(:super_admin) { create(:super_admin) }

  before do
    create(:cohort, :previous)
    create :registration_interest, email: "senco@example.org", course: "npq-senco", created_at: Time.zone.local(2026, 9, 1)
    create :registration_interest, email: "other@example.org", course: "other", notified: true, created_at: Time.zone.local(2026, 9, 2)
    create :user, email_updates_status: :senco, email: "old-style@example.org"
    sign_in_as(super_admin)
  end

  scenario "super admin sees the registration interests" do
    visit("/admin")
    click_link "Registration closed"
    click_link "Users who’ve requested emails about registration reopening"

    expect(page).to have_text("Users who’ve requested emails about registration reopening (2)")
    expect(page).to have_text("senco@example.org")
    expect(page).to have_text("other@example.org")
    expect(page).not_to have_text("old-style@example.org")
  end

  scenario "unsubscribe user" do
    visit("/admin")
    click_link "Registration closed"
    click_link "Users who’ve requested emails about registration reopening"
    within("tr", text: "senco@example.org") { click_link "Unsubscribe" }
    click_link "Unsubscribe"
    expect(page).to have_text("Email 'senco@example.org' unsubscribed")
    expect(RegistrationInterest.pluck(:email)).to eq(%w[other@example.org])
  end

  scenario "super admin exports all registration interests as CSV" do
    visit("/admin")
    click_link "Registration closed"
    click_link "Users who’ve requested emails about registration reopening"
    click_link "Export all", exact: true
    expect(page.body).to eq(
      "Email,Interested in SENCO?,Notified,Subscription Date\n  senco@example.org,Yes,No,2026-09-01\n  other@example.org,No,Yes,2026-09-02\n",
    )
  end

  scenario "super admin exports registration interests with SENCO interest as CSV" do
    visit("/admin")
    click_link "Registration closed"
    click_link "Users who’ve requested emails about registration reopening"
    click_link "Export all with SENCO interest"
    expect(page.body).to eq(
      "Email,Interested in SENCO?,Notified,Subscription Date\n  senco@example.org,Yes,No,2026-09-01\n",
    )
  end
end
