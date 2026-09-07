# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Statement - change output_fee", :no_js, type: :feature do
  include Helpers::AdminLogin

  let(:statement) { create(:statement, output_fee: false) }

  before { allow(Statements::ChangeOutputFeeJob).to receive(:perform_later) }

  scenario "updating output fee" do
    sign_in_as create(:super_admin)

    visit admin_finance_statement_path(statement)
    within(".govuk-summary-list__row", text: "Output statement") do
      click_link "Change"
    end

    # check cancel
    expect(page).to have_current_path admin_finance_statements_change_output_fee_path(statement)
    click_link "Cancel"

    expect(page).to have_current_path admin_finance_statement_path(statement)
    within(".govuk-summary-list__row", text: "Output statement") do
      click_link "Change"
    end

    expect(page).to have_current_path admin_finance_statements_change_output_fee_path(statement)
    click_button "Change output statement"
    expect(Statements::ChangeOutputFeeJob).not_to have_received(:perform_later)
    expect(page).not_to have_content "statement is being changed"

    expect(page).to have_current_path admin_finance_statement_path(statement)
    within(".govuk-summary-list__row", text: "Output statement") do
      click_link "Change"
    end

    expect(page).to have_current_path admin_finance_statements_change_output_fee_path(statement)
    expect(page).to have_content "There is no later output statement and no declarations or milestones will be moved"
    choose "Output statement"
    click_button "Change output statement"
    expect(Statements::ChangeOutputFeeJob).to have_received(:perform_later)

    expect(page).to have_current_path admin_finance_statement_path(statement)
    expect(page).to have_content "Output statement is being changed and declarations moved - this will take a few minutes"
  end

  context "when the statement is payable" do
    let(:statement) { create(:statement, :payable, output_fee: false) }

    scenario "it shows an error" do
      sign_in_as create(:super_admin)

      visit admin_finance_statement_path(statement)
      within(".govuk-summary-list__row", text: "Output statement") do
        click_link "Change"
      end

      expect(page).to have_current_path admin_finance_statements_change_output_fee_path(statement)
      expect(page).to have_content "There is no later output statement and no declarations or milestones will be moved"
      choose "Output statement"
      click_button "Change output statement"
      expect(Statements::ChangeOutputFeeJob).not_to have_received(:perform_later)

      expect(page).to have_current_path admin_finance_statements_change_output_fee_path(statement)
      expect(page).to have_content I18n.t("activemodel.errors.models.statements/change_output_fee.attributes.allow_payable_statement_changes.accepted")
    end
  end

  scenario "when attempting to change output as a regular admin" do
    sign_in_as create(:admin)

    visit admin_finance_statement_path(statement)
    within(".govuk-summary-list__row", text: "Output statement") do |row|
      expect(row).not_to have_link("Change")
    end

    visit admin_finance_statements_change_output_fee_path(statement)
    expect(page).to have_current_path sign_in_path
  end

  scenario "when not signed in" do
    visit admin_finance_statement_path(statement)
    expect(page).to have_current_path sign_in_path
  end
end
