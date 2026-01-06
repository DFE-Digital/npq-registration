# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Statement payment", type: :feature do
  include Helpers::AdminLogin

  let(:statement) { create(:statement, :open) }
  let(:component) { NpqSeparation::Admin::StatementDetailsComponent.new(statement:, link_to_voids: false) }

  before do
    create(:declaration, :payable, statement:)
    # contracts needed to test queries in summary calculator are optimised
    create(:contract, course: create(:course, :leading_teaching), statement:)
    create(:contract, course: create(:course, :leading_behaviour_culture), statement:)
    statement.update!(state: "payable", deadline_date: Time.zone.yesterday)
    sign_in_as(create(:admin))
    visit(npq_separation_admin_finance_statement_path(statement))
  end

  scenario "marking a statement as paid" do
    expect(page).to have_css("h1", text: "#{statement.lead_provider.name}, #{Date::MONTHNAMES[statement.month]} #{statement.year}")
    click_link "Authorise for payment"

    expect(page).to have_css("h1", text: "Check #{Date::MONTHNAMES[statement.month]} #{statement.year} statement details")
    expect(page).to have_component(component)

    perform_enqueued_jobs do
      check "Yes, I'm ready to authorise this for payment", visible: :all
      click_button "Authorise for payment"
    end

    expect(page).to have_css("h1", text: "#{statement.lead_provider.name}, #{Date::MONTHNAMES[statement.month]} #{statement.year}")
    expect(page).to have_css(".govuk-summary-list__value", text: /Authorised for payment at 1?\d:\d\d[ap]m on \d?\d [A-Z][a-z]{2} 20\d\d/)
  end

  scenario "marking a statement as paid before job has run" do
    expect(page).to have_css("h1", text: "#{statement.lead_provider.name}, #{Date::MONTHNAMES[statement.month]} #{statement.year}")
    click_link "Authorise for payment"

    expect(page).to have_css("h1", text: "Check #{Date::MONTHNAMES[statement.month]} #{statement.year} statement details")
    expect(page).to have_component(component)

    check "Yes, I'm ready to authorise this for payment", visible: :all
    click_button "Authorise for payment"

    expect(page).to have_css("h1", text: "#{statement.lead_provider.name}, #{Date::MONTHNAMES[statement.month]} #{statement.year}")
    expect(page).to have_css(".govuk-notification-banner__title", text: "Authorising for payment")
    expect(page).to have_css(".govuk-notification-banner__content", text: /Requested at \d\d?:\d\d[ap]m/)
  end
end
