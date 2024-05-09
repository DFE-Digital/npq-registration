require "rails_helper"

RSpec.feature "Listing and viewing statements", type: :feature do
  include Helpers::AdminLogin

  let(:statements_per_page) { Pagy::DEFAULT[:items] }

  before do
    create_list(:statement, statements_per_page + 1)
    sign_in_as(create(:admin))
  end

  scenario "viewing the list of statements" do
    visit(npq_separation_admin_finance_statements_path)

    expect(page).to have_css("h1", text: "Statements")

    Statement.order(payment_date: :asc).limit(statements_per_page).each do |statement|
      expect(page).to have_link("View", href: npq_separation_admin_finance_statement_path(statement))
    end

    expect(page).to have_css(".govuk-pagination__item--current", text: 1)
  end

  scenario "navigating to the second page of statements" do
    visit(npq_separation_admin_finance_statements_path)

    click_on("Next")

    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_css(".govuk-pagination__item--current", text: "2")
  end

  scenario "viewing statement details" do
    visit(npq_separation_admin_finance_statements_path)

    statement = Statement.order(payment_date: :asc).first

    click_link("View", href: npq_separation_admin_finance_statement_path(statement))

    expect(page).to have_css("h1", text: "Statement #{statement.id}")

    within(".govuk-summary-list") do |summary_list|
      start_year = statement.cohort.start_year
      expect(summary_list).to have_summary_item("ID", statement.id)
      expect(summary_list).to have_summary_item("Lead provider", statement.lead_provider.name)
      expect(summary_list).to have_summary_item("Cohort", "#{start_year}/#{start_year.next - 2000}")
      expect(summary_list).to have_summary_item("Status", statement.state.humanize)
    end
  end
end
