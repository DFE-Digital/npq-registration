# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Statement payment", :ecf_api_disabled, type: :feature do
  include Helpers::AdminLogin

  let(:statement) { create(:statement, :payable) }

  before do
    create(:declaration, :payable, statement:)
    sign_in_as(create(:admin))
    visit(npq_separation_admin_finance_statement_path(statement))
  end

  scenario "marking a statement as paid" do
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
