require "rails_helper"

RSpec.feature "Listing and viewing applications", type: :feature do
  include Helpers::AdminLogin

  before do
    FactoryBot.create_list(:application, Pagy::DEFAULT[:items] + 1)
    sign_in_as(create(:admin))
  end

  scenario "visiting the applications index" do
    visit(npq_separation_admin_applications_path)

    expect(page).to have_css("h1", text: "All applications")
    expect(page).to have_css("table.govuk-table")
    expect(page).to have_css("nav.govuk-pagination")
  end

  scenario "viewing a single application"
end
