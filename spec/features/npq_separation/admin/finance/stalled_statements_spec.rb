# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Stalled statements", type: :feature do
  include Helpers::AdminLogin

  let(:statement) { create(:statement, :payable) }
  let(:component) { NpqSeparation::Admin::StatementDetailsComponent.new(statement:, link_to_voids: false) }

  before do
    create(:declaration, :payable, statement:)
    sign_in_as(create(:admin))
    visit(npq_separation_admin_finance_statement_path(statement))
  end

  scenario "showing a stalled payments" do
    expect(page).to have_css("h1", text: "Statement #{statement.id}")
    click_link "Authorise for payment"

    expect(page).to have_css("h1", text: "Check #{Date::MONTHNAMES[statement.month]} #{statement.year} statement details")
    expect(page).to have_component(component)

    check "Yes, I'm ready to authorise this for payment", visible: :all
    click_button "Authorise for payment"

    expect(page).to have_css("h1", text: "Statement #{statement.id}")

    statement.update!(marked_as_paid_at: (Statement::AUTHORISATION_GRACE_TIME * 2).ago)

    click_link "Finance"
    click_link "Stalled statements (1)"

    within("td:nth-of-type(5)") do
      click_link("View")
    end
    expect(page).to have_css(".govuk-notification-banner__title", text: "Authorising for payment delayed")
    expect(page).to have_css(".govuk-notification-banner__content", text: /Requested at \d\d?:\d\d[ap]m/)
  end
end
