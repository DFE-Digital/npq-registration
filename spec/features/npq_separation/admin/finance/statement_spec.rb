# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Statement", type: :feature do
  include Helpers::AdminLogin
  include ActionView::Helpers::NumberHelper

  let(:statement) { create(:statement) }

  let!(:contracts) do
    [
      create(:contract, course: create(:course, :leading_teaching), statement:),
      create(:contract, course: create(:course, :leading_behaviour_culture), statement:),
      create(:contract, course: create(:course, :leading_primary_mathmatics), statement:),
    ]
  end

  before do
    create(:schedule, :npq_leadership_autumn)
    create(:schedule, :npq_leadership_spring)
    create(:schedule, :npq_specialist_autumn)
    create(:schedule, :npq_specialist_spring)

    sign_in_as(create(:admin))
  end

  scenario "shows side navigation with current statement highlighted" do
    visit(npq_separation_admin_finance_statement_path(statement))

    within "#side-navigation" do |side_navigation|
      expect(side_navigation).to have_content("Finance statement")
      expect(side_navigation).to have_content("#{statement.lead_provider.name}, #{Date::MONTHNAMES[statement.month]} #{statement.year}")
    end
  end

  scenario "see details" do
    visit(npq_separation_admin_finance_statement_path(statement))

    expect(page).to have_css("h1", text: "#{statement.lead_provider.name}, #{Date::MONTHNAMES[statement.month]} #{statement.year}")

    find("span", text: "Statement ID").click
    within("#statement-id") do
      expect(page).to have_content(statement.ecf_id)
    end

    start_year = statement.cohort.start_year
    expect(page).to have_content("Cohort: #{start_year}/#{start_year.next - 2000}")
    expect(page).to have_content("Output payment date: #{statement.payment_date.to_fs(:govuk)}")
    expect(page).to have_content("Status: #{statement.state.humanize}")

    component = NpqSeparation::Admin::StatementSummaryComponent.new(statement:)
    expect(page).to have_component(component)

    expect(page).to have_css("a", text: "Save as PDF")
    expect(page).to have_link("Download declarations (CSV)", href: npq_separation_admin_finance_assurance_report_path(statement, format: :csv))

    contracts.each do |contract|
      component = NpqSeparation::Admin::CoursePaymentOverviewComponent.new(contract:)
      expect(page).to have_component(component)
    end

    expect(page).not_to have_text("Standalone payments")

    expect(page).to be_accessible
  end

  scenario "see special course details" do
    contract = contracts.last
    contract.contract_template.update! special_course: true

    visit npq_separation_admin_finance_statement_path(statement)

    within "#special-contracts-warning" do
      expect(page).to have_content("#{contract.course.name} has standalone payments")
      expect(page).to have_link("View payments for this course", href: "#standalone_payments")
    end

    within "h4#standalone_payments" do
      expect(page).to have_content("Standalone payments")
    end

    within "h4#standalone_payments + .govuk-summary-card" do
      component = NpqSeparation::Admin::CoursePaymentOverviewComponent.new(contract:)
      expect(page).to have_component(component)
    end

    expect(page).to be_accessible
  end

  scenario "see the contract information for all courses of a statement" do
    visit npq_separation_admin_finance_statement_path(statement)
    find("span", text: "Contract Information").click

    within all(".govuk-details__text", visible: false).last do
      contracts.each do |contract|
        expect(page).to have_content(contract.course.name)
        expect(page).to have_content(contract.recruitment_target)
        expect(page).to have_content(number_to_currency(contract.per_participant))
      end
    end

    expect(page).to be_accessible
  end
end
