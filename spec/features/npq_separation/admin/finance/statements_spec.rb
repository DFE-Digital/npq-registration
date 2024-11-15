require "rails_helper"

RSpec.feature "Listing and viewing statements", :ecf_api_disabled, type: :feature do
  include Helpers::AdminLogin

  let(:statements_per_page) { Pagy::DEFAULT[:limit] }

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
      expect(summary_list).to have_summary_item("ECF ID", statement.ecf_id)
      expect(summary_list).to have_summary_item("Lead provider", statement.lead_provider.name)
      expect(summary_list).to have_summary_item("Cohort", "#{start_year}/#{start_year.next - 2000}")
      expect(summary_list).to have_summary_item("Status", statement.state.humanize)
    end

    expect(page).to have_css("a", text: "Save as PDF")
  end

  scenario "viewing a statement with a special course" do
    statement = Statement.first

    create(:schedule, :npq_specialist_autumn)
    maths_course = create(:course, :leading_primary_mathmatics)
    create(:contract, statement:, course: maths_course).tap { _1.contract_template.update! special_course: true }

    visit npq_separation_admin_finance_statement_path(statement)

    within ".govuk-warning-text" do
      expect(page).to have_content("#{maths_course.name} has standalone payments")
      expect(page).to have_link("View payments for this course", href: "#standalone_payments")
    end

    within "h4#standalone_payments" do
      expect(page).to have_content("Standalone payments")
    end

    within "h4#standalone_payments + .app-statement-block h2" do
      expect(page).to have_content(maths_course.name)
    end
  end

  scenario "marking a statement as paid" do
    statement = create(:statement, :payable)
    create(:declaration, :payable, statement:)

    visit(npq_separation_admin_finance_statement_path(statement))
    expect(page).to have_css("h1", text: "Statement #{statement.id}")
    click_link "Authorise for payment"

    expect(page).to have_css("h1", text: "Check #{Date::MONTHNAMES[statement.month]} #{statement.year} statement details")
    expect(page).to have_css(".statement-details-component", text: "Output payment")

    perform_enqueued_jobs do
      check "Yes, I'm ready to authorise this for payment", visible: :all
      click_button "Authorise for payment"
    end

    expect(page).to have_css("h1", text: "Statement #{statement.id}")
    expect(page).to have_css(".govuk-tag", text: /Authorised for payment at 1?\d:\d\d[ap]m on \d?\d [A-Z][a-z]{2} 20\d\d/)
  end

  scenario "marking a statement as paid before job has run" do
    statement = create(:statement, :payable)
    create(:declaration, :payable, statement:)

    visit(npq_separation_admin_finance_statement_path(statement))
    expect(page).to have_css("h1", text: "Statement #{statement.id}")
    click_link "Authorise for payment"

    expect(page).to have_css("h1", text: "Check #{Date::MONTHNAMES[statement.month]} #{statement.year} statement details")
    expect(page).to have_css(".statement-details-component", text: "Output payment")

    check "Yes, I'm ready to authorise this for payment", visible: :all
    click_button "Authorise for payment"

    expect(page).to have_css("h1", text: "Statement #{statement.id}")
    expect(page).to have_css(".govuk-notification-banner__title", text: "Authorising for payment")
    expect(page).to have_css(".govuk-notification-banner__content", text: /Requested at \d\d?:\d\d[ap]m/)
  end
end
