# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Statement - change output_fee", :no_js, type: :feature do
  include Helpers::AdminLogin

  let(:statement) { create(:statement) }

  before { sign_in_as(create(:super_admin)) }

  scenario "updating output fee" do
    visit(admin_finance_statement_path(statement))
    within(".govuk-summary-card", text: "Statement summary") do
      click_link "Change"
    end

    # check cancel
    click_link "Cancel"
    expect(page).to have_current_path(admin_finance_statement_path(statement))

    # check blank date validation
    within(".govuk-summary-card", text: "Statement summary") do
      click_link "Change"
    end
    click_button "Change output statement"

    expect(page).to have_content I18n.t("activemodel.errors.models.statements/change_deadline_date.attributes.deadline_date.blank")

    # check non-numeric characters validation
    click_button "Change output fee"

    expect(page).to have_content I18n.t("activemodel.errors.models.statements/change_deadline_date.attributes.deadline_date.blank")

    choose "Yes"
    click_button "Change output statement"

    expect(page).to have_content I18n.t("activemodel.errors.models.statements/change_deadline_date.attributes.deadline_date.invalid")

    # check valid date
    new_deadline_date = statement.payment_date - 1.month
    fill_in "statements_change_deadline_date[deadline_date(3i)]", with: new_deadline_date.day
    fill_in "statements_change_deadline_date[deadline_date(2i)]", with: new_deadline_date.month
    fill_in "statements_change_deadline_date[deadline_date(1i)]", with: new_deadline_date.year

    click_button "Change date"

    expect(page).to have_content("Declaration deadline changed")
    expect(page).to have_current_path(admin_finance_statement_path(statement))
  end

  context "when the statement is payable" do
    let(:statement) { create(:statement, :payable) }

    scenario "it shows an error" do
      visit(admin_finance_statements_change_deadline_date_path(statement))

      new_deadline_date = statement.payment_date - 1.month
      fill_in "statements_change_deadline_date[deadline_date(3i)]", with: new_deadline_date.day
      fill_in "statements_change_deadline_date[deadline_date(2i)]", with: new_deadline_date.month
      fill_in "statements_change_deadline_date[deadline_date(1i)]", with: new_deadline_date.year

      click_button "Change date"

      expect(page).to have_content I18n.t("activerecord.errors.models.statement.attributes.base.statement_payable")
    end
  end
end
