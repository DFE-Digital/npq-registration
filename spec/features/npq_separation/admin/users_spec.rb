require "rails_helper"

RSpec.feature "Listing and viewing users", type: :feature do
  include Helpers::AdminLogin

  let(:users_per_page) { Pagy::DEFAULT[:items] }

  before do
    create_list(:user, users_per_page + 1, :with_get_an_identity_id)
    sign_in_as(create(:admin))
  end

  scenario "viewing the list of users" do
    visit(npq_separation_admin_users_path)

    expect(page).to have_css("h1", text: "All participants")

    User.limit(users_per_page).each do |user|
      expect(page).to have_link(user.full_name, href: npq_separation_admin_user_path(user))
      expect(page).to have_css("td", text: user.trn)
      expect(page).to have_css("td", text: user.created_at.to_date.to_formatted_s(:govuk))
    end

    expect(page).to have_css(".govuk-pagination__item--current", text: 1)
  end

  scenario "navigating to the second page of users" do
    visit(npq_separation_admin_users_path)

    click_on("Next")

    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_css(".govuk-pagination__item--current", text: "2")
  end

  scenario "viewing user details" do
    visit(npq_separation_admin_users_path)

    user = User.first

    all_participants_table = find("h1", text: "All participants").sibling("table")
    all_participants_table.click_link(user.full_name)

    expect(page).to have_css("h1", text: user.full_name)

    within(".govuk-summary-list") do |summary_list|
      expect(summary_list).to have_summary_item("ID", user.id)
      expect(summary_list).to have_summary_item("ECF ID", user.ecf_id)
      expect(summary_list).to have_summary_item("Email", user.email)
      expect(summary_list).to have_summary_item("Name", user.full_name)
      expect(summary_list).to have_summary_item("TRN", user.trn)
      expect(summary_list).to have_summary_item("TRN validated", "No")
      expect(summary_list).to have_summary_item("Get an Identity ID", user.get_an_identity_id)
    end
  end
end
