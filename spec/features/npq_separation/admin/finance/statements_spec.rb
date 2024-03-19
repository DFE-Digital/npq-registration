require "rails_helper"

RSpec.feature "Listing and viewing statements", type: :feature do
  include Helpers::AdminLogin

  before do
    FactoryBot.create_list(:statement, Pagy::DEFAULT[:items] + 1)
    sign_in_as(create(:admin))
  end

  scenario "visiting the statements index" do
    visit(npq_separation_admin_finance_statements_path)

    expect(page).to have_css("h1", text: "Statements")
    expect(page).to have_css("table.govuk-table")
    expect(page).to have_css("nav.govuk-pagination")
  end

  scenario "viewing a single statement"
end
