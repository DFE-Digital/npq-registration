# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Statement", :ecf_api_disabled, type: :feature do
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
    create(:schedule, :npq_specialist_autumn)

    sign_in_as(create(:admin))
  end

  scenario "see details" do
    visit(npq_separation_admin_finance_statement_path(statement))

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

    contracts.each do |contract|
      component = NpqSeparation::Admin::CoursePaymentOverviewComponent.new(contract:)
      expect(page).to have_component(component)
    end

    expect(page).not_to have_text("Standalone payments")
  end

  scenario "see special course details" do
    contract = contracts.last
    contract.contract_template.update! special_course: true

    visit npq_separation_admin_finance_statement_path(statement)

    within ".govuk-warning-text" do
      expect(page).to have_content("#{contract.course.name} has standalone payments")
      expect(page).to have_link("View payments for this course", href: "#standalone_payments")
    end

    within "h4#standalone_payments" do
      expect(page).to have_content("Standalone payments")
    end

    within "h4#standalone_payments + .app-statement-block" do
      component = NpqSeparation::Admin::CoursePaymentOverviewComponent.new(contract:)
      expect(page).to have_component(component)
    end
  end

  scenario "see the contract information for all courses of a statement" do
    visit npq_separation_admin_finance_statement_path(statement)
    find("span", text: "Contract Information").click

    within first(".govuk-details__text", visible: false) do
      contracts.each do |contract|
        expect(page).to have_content(contract.course.name)
        expect(page).to have_content(contract.recruitment_target)
        expect(page).to have_content(number_to_currency(contract.per_participant))
      end
    end
  end
end
